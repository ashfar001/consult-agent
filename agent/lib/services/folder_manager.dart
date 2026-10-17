import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/api/mock_api_client.dart';
import '../data/db/database.dart';
import '../data/models/models.dart';
import 'logging.dart';

const defaultTemplate = [
  '01_Survey',
  '02_Drawings',
  '03_Structural',
  '04_KSMART',
  '05_Exports',
  '06_Client-Docs',
];

/// Replaces characters Windows forbids in file names.
String sanitizeName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '');
  return cleaned.isEmpty ? 'Project' : cleaned;
}

/// Picks the template subfolder that matches a task title, or null.
///
/// "Structural column layout" → 03_Structural, "K-SMART permit drawings" →
/// 04_KSMART. More specific topics are checked before the generic
/// "drawings" so a structural drawing opens the structural folder.
String? subfolderForTask(String taskTitle, Iterable<String> subfolders) {
  final title = taskTitle.toLowerCase();
  const rules = <(String, List<String>)>[
    ('ksmart', ['k-smart', 'ksmart', 'permit']),
    (
      'structural',
      ['structur', 'column', 'beam', 'footing', 'foundation', 'slab'],
    ),
    ('survey', ['survey', 'site visit', 'levels']),
    ('exports', ['export', 'pdf', 'plot', 'print']),
    ('client', ['client', 'letter', 'agreement']),
    (
      'drawings',
      [
        'drawing',
        'plan',
        'elevation',
        'section',
        'layout',
        'revit',
        'model',
        'cad',
      ],
    ),
  ];
  for (final (key, words) in rules) {
    if (!words.any(title.contains)) continue;
    for (final folder in subfolders) {
      if (folder
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll('-', '')
          .contains(key)) {
        return folder;
      }
    }
  }
  return null;
}

/// Progress of a folder sync.
typedef SyncProgress = void Function(int done, int total, String path);

class FolderSyncResult {
  const FolderSyncResult({
    required this.folder,
    required this.downloaded,
    required this.failed,
    required this.readOnly,
    required this.offline,
  });

  final String folder;
  final int downloaded;
  final List<String> failed;

  /// Files held by another worker, downloaded read-only: path → holder.
  final Map<String, String> readOnly;

  /// The file list could not be fetched; the existing folder was opened as is.
  final bool offline;
}

/// Creates the project folder, brings it up to date, and opens it.
class FolderManager {
  FolderManager({
    required this.config,
    required this.db,
    required this.api,
    Dio? dio,
    this.currentWorkerName,
  }) : _dio = dio ?? Dio();

  final AppConfig config;
  final AgentDatabase db;
  final ApiClient api;
  final Dio _dio;

  /// Name that may check files out; others' files open read-only.
  final String? currentWorkerName;

  /// `D:\Projects` if it exists or can be created, else the user fallback.
  String projectsRoot() {
    for (final root in [config.projectsRoot, config.fallbackProjectsRoot]) {
      try {
        Directory(root).createSync(recursive: true);
        return root;
      } on FileSystemException {
        continue;
      }
    }
    return config.fallbackProjectsRoot;
  }

  String folderFor(Project project) =>
      p.join(projectsRoot(), '${project.code}_${sanitizeName(project.name)}');

  /// Creates the folder + template, downloads missing/newer files.
  Future<FolderSyncResult> sync(
    Project project, {
    SyncProgress? onProgress,
  }) async {
    final folder = folderFor(project);
    final template = project.folderTemplate.isEmpty
        ? defaultTemplate
        : project.folderTemplate;
    for (final sub in template) {
      Directory(p.join(folder, sub)).createSync(recursive: true);
    }

    final List<RemoteFile> remote;
    try {
      remote = await api.projectFiles(project.id);
    } on ApiException catch (e) {
      log.w('File list unavailable (${e.message}); opening local folder');
      return FolderSyncResult(
        folder: folder,
        downloaded: 0,
        failed: const [],
        readOnly: const {},
        offline: true,
      );
    }

    final local = {
      for (final v in await db.fileDao.forProject(project.id))
        v.path: v.version,
    };
    final todo = remote.where((f) {
      final target = File(p.join(folder, f.path));
      return !target.existsSync() || (local[f.path] ?? 0) < f.version;
    }).toList();

    var done = 0;
    final failed = <String>[];
    final readOnly = <String, String>{};
    for (final f in todo) {
      onProgress?.call(done, todo.length, f.path);
      try {
        await _download(f, p.join(folder, f.path));
        await db.fileDao.upsert(
          projectId: project.id,
          path: f.path,
          fileId: f.fileId,
          version: f.version,
          at: DateTime.now(),
        );
        final holder = f.checkedOutBy;
        if (holder != null && holder != currentWorkerName) {
          readOnly[f.path] = holder;
          await _setReadOnly(p.join(folder, f.path));
        }
      } on Object catch (e) {
        log.w('Download failed for ${f.path}: $e');
        failed.add(f.path);
      }
      done++;
    }
    for (final f in remote) {
      final holder = f.checkedOutBy;
      if (holder != null && holder != currentWorkerName) {
        readOnly[f.path] = holder;
      }
    }
    onProgress?.call(todo.length, todo.length, '');
    return FolderSyncResult(
      folder: folder,
      downloaded: todo.length - failed.length,
      failed: failed,
      readOnly: readOnly,
      offline: false,
    );
  }

  /// Downloads to a temp file, then renames, so a crash never leaves a
  /// half-written drawing in place.
  Future<void> _download(RemoteFile f, String target) async {
    final tmp = File('$target.part');
    tmp.parent.createSync(recursive: true);
    if (f.downloadUrl.startsWith('mock://')) {
      await tmp.writeAsBytes(MockApiClient.dummyContent(f.downloadUrl, f.size));
    } else {
      await _dio.download(f.downloadUrl, tmp.path);
    }
    final dest = File(target);
    if (dest.existsSync()) {
      await _clearReadOnly(target);
      dest.deleteSync();
    }
    tmp.renameSync(target);
  }

  Future<void> _setReadOnly(String path) async {
    if (!Platform.isWindows) return;
    await Process.run('attrib', ['+R', path]);
  }

  Future<void> _clearReadOnly(String path) async {
    if (!Platform.isWindows) return;
    await Process.run('attrib', ['-R', path]);
  }

  /// The folder to open for [task]: its matching subfolder if there is one.
  String folderForTask(Project project, ProjectTask task, String folder) {
    final template = project.folderTemplate.isEmpty
        ? defaultTemplate
        : project.folderTemplate;
    final sub = subfolderForTask(task.title, template);
    if (sub != null && Directory(p.join(folder, sub)).existsSync()) {
      return p.join(folder, sub);
    }
    return folder;
  }

  /// Opens the task's folder (else the main file, else the project folder)
  /// in Explorer.
  Future<void> open(Project project, String folder, {ProjectTask? task}) async {
    if (!Platform.isWindows) return;
    final target = task == null ? folder : folderForTask(project, task, folder);
    final main = project.mainFile;
    if (target == folder &&
        main != null &&
        File(p.join(folder, main)).existsSync()) {
      await Process.run('explorer.exe', [p.join(folder, main)]);
    } else {
      await Process.run('explorer.exe', [target]);
    }
  }
}
