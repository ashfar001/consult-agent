import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/api/api_client.dart';
import '../data/db/database.dart';
import 'logging.dart';
import 'sync_worker.dart';

const multipartThreshold = 50 * 1024 * 1024;

/// A file to upload.
class UploadRequest {
  const UploadRequest({required this.localPath, required this.remotePath});

  final String localPath;

  /// Path relative to the project folder, forward slashes.
  final String remotePath;
}

class UploadProgress {
  const UploadProgress(
    this.clientId,
    this.remotePath,
    this.fraction,
    this.state,
  );

  final String clientId;
  final String remotePath;
  final double fraction;

  /// queued | uploading | confirmed | failed
  final String state;
}

class EnqueueResult {
  const EnqueueResult({
    required this.queued,
    required this.tooLarge,
    required this.clientIds,
  });

  final List<String> queued;

  /// Upload row ids, in the same order as [queued].
  final List<String> clientIds;

  /// Remote paths skipped because they exceed the size cap.
  final List<String> tooLarge;
}

/// Presigned-URL uploads, queued in SQLite and retried until confirmed.
///
/// Flow per file: `files/upload-url` → PUT to storage (single, or 50 MB parts
/// with completed parts remembered so a retry resumes) → `files/confirm`,
/// which creates the new version.
class Uploader {
  Uploader({
    required this.db,
    required this.api,
    required this.clock,
    required this.maxFileBytes,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final AgentDatabase db;
  final ApiClient api;
  final DateTime Function() clock;
  final int maxFileBytes;
  final Dio _dio;

  final _progress = StreamController<UploadProgress>.broadcast();
  bool _running = false;

  Stream<UploadProgress> get progress => _progress.stream;

  static int fileSize(String path) => File(path).lengthSync();

  Future<EnqueueResult> enqueue({
    required String projectId,
    required List<UploadRequest> files,
    String note = '',
    String? taskId,
    bool completeTask = false,
  }) async {
    final queued = <String>[];
    final ids = <String>[];
    final tooLarge = <String>[];
    for (final f in files) {
      final file = File(f.localPath);
      if (!file.existsSync()) continue;
      final size = file.lengthSync();
      if (size > maxFileBytes) {
        tooLarge.add(f.remotePath);
        continue;
      }
      final id = const Uuid().v4();
      await db.uploadDao.enqueue(
        UploadsCompanion.insert(
          clientId: id,
          projectId: projectId,
          localPath: f.localPath,
          remotePath: f.remotePath,
          size: size,
          state: 'queued',
          note: Value(note),
          taskId: Value(taskId),
          completeTask: Value(completeTask),
          createdAt: clock(),
        ),
      );
      queued.add(f.remotePath);
      ids.add(id);
      _progress.add(UploadProgress(id, f.remotePath, 0, 'queued'));
    }
    return EnqueueResult(queued: queued, tooLarge: tooLarge, clientIds: ids);
  }

  /// Uploads everything pending. Returns the number confirmed this run.
  /// Stops at the first transient failure; the rest stay queued.
  Future<int> processQueue() async {
    if (_running) return 0;
    _running = true;
    var confirmed = 0;
    try {
      for (final row in await db.uploadDao.pending()) {
        try {
          await _upload(row);
          confirmed++;
        } on ApiException catch (e) {
          if (e.isRetryable || e.isUnauthorized) {
            await _bump(row, e.message);
            break;
          }
          await _fail(row, e.message);
        } on DioException catch (e) {
          await _bump(row, e.message ?? 'network error');
          break;
        } on FileSystemException catch (e) {
          await _fail(row, e.message);
        }
      }
    } finally {
      _running = false;
    }
    return confirmed;
  }

  Future<void> _bump(UploadRow row, String error) async {
    log.w('Upload of ${row.remotePath} will retry: $error');
    await db.uploadDao.patch(
      row.clientId,
      UploadsCompanion(attempts: Value(row.attempts + 1)),
    );
    _progress.add(UploadProgress(row.clientId, row.remotePath, 0, 'queued'));
  }

  Future<void> _fail(UploadRow row, String error) async {
    log.e('Upload of ${row.remotePath} failed: $error');
    await db.uploadDao.patch(
      row.clientId,
      const UploadsCompanion(state: Value('failed')),
    );
    _progress.add(UploadProgress(row.clientId, row.remotePath, 0, 'failed'));
  }

  Future<void> _upload(UploadRow row) async {
    final file = File(row.localPath);
    if (!file.existsSync()) {
      throw FileSystemException('File missing', row.localPath);
    }
    void emit(double f) => _progress.add(
      UploadProgress(row.clientId, row.remotePath, f, 'uploading'),
    );
    emit(0);

    var uploadId = row.uploadId;
    final parts = (jsonDecode(row.partsJson) as Map<String, dynamic>);
    if (uploadId == null) {
      final target = await api.requestUploadUrl(
        clientId: row.clientId,
        projectId: row.projectId,
        path: row.remotePath,
        size: row.size,
      );
      uploadId = target.uploadId;
      parts['urls'] = target.isMultipart ? target.parts : [target.url];
      parts['multipart'] = target.isMultipart;
      parts['done'] = <int>[];
      await db.uploadDao.patch(
        row.clientId,
        UploadsCompanion(
          uploadId: Value(uploadId),
          partsJson: Value(jsonEncode(parts)),
          state: const Value('uploading'),
        ),
      );
    }

    final urls = (parts['urls'] as List).map((e) => '$e').toList();
    final done = <int>{...(parts['done'] as List).map((e) => e as int)};
    if (parts['multipart'] == true) {
      final raf = await file.open();
      try {
        for (var i = 0; i < urls.length; i++) {
          if (done.contains(i)) continue;
          await raf.setPosition(i * multipartThreshold);
          final chunk = await raf.read(multipartThreshold);
          await _put(urls[i], Stream.value(chunk), chunk.length);
          done.add(i);
          parts['done'] = done.toList();
          await db.uploadDao.patch(
            row.clientId,
            UploadsCompanion(partsJson: Value(jsonEncode(parts))),
          );
          emit(done.length / urls.length);
        }
      } finally {
        await raf.close();
      }
    } else {
      await _put(urls.first, file.openRead(), row.size);
    }

    final ref = await api.confirmUpload(uploadId: uploadId, note: row.note);
    await db.uploadDao.patch(
      row.clientId,
      UploadsCompanion(
        state: const Value('confirmed'),
        resultFileId: Value(ref.fileId),
      ),
    );
    await db.fileDao.upsert(
      projectId: row.projectId,
      path: row.remotePath,
      fileId: ref.fileId,
      version: ref.version,
      at: clock(),
    );
    if (row.completeTask && row.taskId != null) {
      await db.outboxDao.enqueue(
        clientId: 'task-${row.clientId}',
        kind: OutboxKind.taskComplete,
        payload: {'task_id': row.taskId, 'note': row.note},
        now: clock(),
      );
    }
    _progress.add(UploadProgress(row.clientId, row.remotePath, 1, 'confirmed'));
  }

  Future<void> _put(String url, Stream<List<int>> data, int length) async {
    if (url.startsWith('mock://')) return;
    await _dio.put<void>(
      url,
      data: data,
      options: Options(headers: {Headers.contentLengthHeader: length}),
    );
  }

  void dispose() => _progress.close();
}
