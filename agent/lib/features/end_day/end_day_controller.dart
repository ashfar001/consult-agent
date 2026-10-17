import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../data/models/models.dart';
import '../../services/logging.dart';
import '../../services/session_manager.dart';
import '../../services/sync_worker.dart';
import '../../services/uploader.dart';
import '../login/auth_controller.dart';
import '../summary/summary_controller.dart';

class TaskRow {
  const TaskRow({
    required this.taskId,
    required this.title,
    required this.projectCode,
    this.status = TaskStatus.inProgress,
    this.note = '',
  });

  final String taskId;
  final String title;
  final String projectCode;
  final TaskStatus status;
  final String note;

  TaskRow copyWith({TaskStatus? status, String? note}) => TaskRow(
        taskId: taskId,
        title: title,
        projectCode: projectCode,
        status: status ?? this.status,
        note: note ?? this.note,
      );
}

class FileRow {
  const FileRow({
    required this.path,
    required this.remotePath,
    required this.size,
    required this.selected,
    this.tooLarge = false,
  });

  final String path;
  final String remotePath;
  final int size;
  final bool selected;
  final bool tooLarge;

  FileRow withSelected(bool v) => FileRow(
        path: path,
        remotePath: remotePath,
        size: size,
        selected: v,
        tooLarge: tooLarge,
      );
}

class EndDayState {
  const EndDayState({
    this.date = '',
    this.tasks = const [],
    this.files = const [],
    this.summary = '',
    this.notes = '',
    this.busy = false,
    this.error,
  });

  final String date;
  final List<TaskRow> tasks;
  final List<FileRow> files;
  final String summary;
  final String notes;
  final bool busy;
  final String? error;

  EndDayState copyWith({
    String? date,
    List<TaskRow>? tasks,
    List<FileRow>? files,
    String? summary,
    String? notes,
    bool? busy,
    String? Function()? error,
  }) =>
      EndDayState(
        date: date ?? this.date,
        tasks: tasks ?? this.tasks,
        files: files ?? this.files,
        summary: summary ?? this.summary,
        notes: notes ?? this.notes,
        busy: busy ?? this.busy,
        error: error != null ? error() : this.error,
      );
}

/// End Work / Pending Report: collects the day's report, queues the backup
/// uploads and the report itself, then hands over to the Summary.
class EndDayController extends Notifier<EndDayState> {
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  @override
  EndDayState build() => const EndDayState();

  Future<void> load({required bool pending}) async {
    final db = ref.read(dbProvider);
    final today = _dayFmt.format(ref.read(clockProvider)());
    final date = pending
        ? (await db.reportDao.pendingDate(today) ?? today)
        : today;
    final day = _dayFmt.parse(date);
    final sessions = await db.sessionDao
        .sessionsBetween(day, day.add(const Duration(days: 1)));
    final current = ref.read(sessionManagerProvider).project;
    final worked = {
      ...sessions.map((s) => s.projectId),
      if (!pending && current != null) current.id,
    };
    final cached = (await db.projectCacheDao.load()).projects;
    final tasks = [
      for (final p in cached.where((p) => worked.contains(p.id)))
        for (final t in p.openTasks)
          TaskRow(taskId: t.id, title: t.title, projectCode: p.code),
    ];

    final max = ref.read(configProvider).maxUploadFileBytes;
    final watcher = ref.read(fileWatcherProvider);
    final files = pending || current == null
        ? <FileRow>[]
        : [
            for (final path in watcher.changedFiles)
              _fileRow(path, watcher.relative(path), max),
          ];
    state = EndDayState(date: date, tasks: tasks, files: files);
  }

  FileRow _fileRow(String path, String remote, int max) {
    final size = _sizeOf(path);
    return FileRow(
      path: path,
      remotePath: remote,
      size: size,
      selected: size <= max,
      tooLarge: size > max,
    );
  }

  int _sizeOf(String path) {
    try {
      return Uploader.fileSize(path);
    } on Object {
      return 0;
    }
  }

  void setSummary(String v) => state = state.copyWith(summary: v);

  void setNotes(String v) => state = state.copyWith(notes: v);

  void setTask(String id, {TaskStatus? status, String? note}) {
    state = state.copyWith(
      tasks: [
        for (final t in state.tasks)
          t.taskId == id ? t.copyWith(status: status, note: note) : t,
      ],
    );
  }

  void toggleFile(String path, bool v) {
    state = state.copyWith(
      files: [
        for (final f in state.files)
          f.path == path && !f.tooLarge ? f.withSelected(v) : f,
      ],
    );
  }

  /// Submits the report. [pending] reports are for an earlier day.
  Future<void> submit({required bool pending}) async {
    if (state.busy) return;
    if (state.summary.trim().isEmpty) {
      state = state.copyWith(error: () => 'Tell us what you did today');
      return;
    }
    state = state.copyWith(busy: true, error: () => null);
    try {
      final db = ref.read(dbProvider);
      final manager = ref.read(sessionManagerProvider.notifier);
      final session = ref.read(sessionManagerProvider);
      final project = session.project;
      final worker = ref.read(authControllerProvider).worker;
      final now = ref.read(clockProvider)();

      if (session.hasSession) {
        await manager.endSession();
      } else if (session.status == TrackStatus.workdayEnded) {
        manager.declineOvertime();
      }

      // Daily backup: changed files go up as new versions.
      final fileIds = <String>[];
      final chosen = state.files.where((f) => f.selected).toList();
      if (!pending && project != null && chosen.isNotEmpty) {
        final uploader = ref.read(uploaderProvider);
        final queued = await uploader.enqueue(
          projectId: project.id,
          files: [
            for (final f in chosen)
              UploadRequest(localPath: f.path, remotePath: f.remotePath),
          ],
          note: 'Daily backup ${state.date}',
        );
        await uploader.processQueue();
        for (final id in queued.clientIds) {
          final row = await db.uploadDao.byClientId(id);
          if (row?.state == 'confirmed' && row?.resultFileId != null) {
            fileIds.add(row!.resultFileId!);
          }
        }
        ref.read(fileWatcherProvider).markUploaded([
          for (final f in chosen) f.path,
        ]);
      }

      final report = DailyReport(
        clientId: const Uuid().v4(),
        date: _dayFmt.parse(state.date),
        summary: state.summary.trim(),
        notes: state.notes.trim(),
        tasks: [
          for (final t in state.tasks)
            TaskReport(taskId: t.taskId, status: t.status, note: t.note),
        ],
        fileIds: fileIds,
      );
      await db.reportDao.save(
        date: state.date,
        workerId: worker?.id ?? 'unknown',
        json: jsonEncode(report.toJson()),
        submitted: true,
      );
      await db.outboxDao.enqueue(
        clientId: 'report-${state.date}',
        kind: OutboxKind.dailyReport,
        payload: report.toJson(),
        now: now,
      );
      for (final t in state.tasks.where((t) => t.status == TaskStatus.completed)) {
        await db.outboxDao.enqueue(
          clientId: 'done-${t.taskId}-${state.date}',
          kind: OutboxKind.taskComplete,
          payload: {'task_id': t.taskId, 'note': t.note},
          now: now,
        );
      }
      ref.read(syncWorkerProvider).kick();

      ref.read(summaryDateProvider.notifier).set(state.date);
      await ref.read(authControllerProvider.notifier).refreshPending();
      state = state.copyWith(busy: false);
      await ref.read(flowCoordinatorProvider).openSummary();
    } on Object catch (e, st) {
      log.e('Submitting report failed', error: e, stackTrace: st);
      state = state.copyWith(busy: false, error: () => 'Could not save: $e');
    }
  }
}

final endDayControllerProvider =
    NotifierProvider<EndDayController, EndDayState>(EndDayController.new);
