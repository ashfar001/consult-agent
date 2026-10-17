import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../services/session_manager.dart';
import '../../services/uploader.dart';

class UploadItem {
  const UploadItem({
    required this.path,
    required this.remotePath,
    required this.size,
    this.selected = true,
    this.state = 'ready',
    this.progress = 0,
  });

  final String path;
  final String remotePath;
  final int size;
  final bool selected;

  /// ready | queued | uploading | confirmed | failed
  final String state;
  final double progress;

  UploadItem copyWith({bool? selected, String? state, double? progress}) =>
      UploadItem(
        path: path,
        remotePath: remotePath,
        size: size,
        selected: selected ?? this.selected,
        state: state ?? this.state,
        progress: progress ?? this.progress,
      );
}

class UploadState {
  const UploadState({
    this.items = const [],
    this.note = '',
    this.completeTask = false,
    this.busy = false,
    this.message,
  });

  final List<UploadItem> items;
  final String note;
  final bool completeTask;
  final bool busy;
  final String? message;

  UploadState copyWith({
    List<UploadItem>? items,
    String? note,
    bool? completeTask,
    bool? busy,
    String? Function()? message,
  }) => UploadState(
    items: items ?? this.items,
    note: note ?? this.note,
    completeTask: completeTask ?? this.completeTask,
    busy: busy ?? this.busy,
    message: message != null ? message() : this.message,
  );
}

/// Logic for the Upload dialog: pick files, queue, show progress.
class UploadController extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadState();

  /// Lists the files the watcher saw change in this project.
  void load() {
    final watcher = ref.read(fileWatcherProvider);
    state = UploadState(
      items: [
        for (final path in watcher.changedFiles)
          UploadItem(
            path: path,
            remotePath: watcher.relative(path),
            size: File(path).existsSync() ? File(path).lengthSync() : 0,
          ),
      ],
    );
  }

  void toggle(String path, bool value) => state = state.copyWith(
    items: [
      for (final i in state.items)
        i.path == path ? i.copyWith(selected: value) : i,
    ],
  );

  void setNote(String v) => state = state.copyWith(note: v);

  void setCompleteTask(bool v) => state = state.copyWith(completeTask: v);

  /// Adds files outside the change list. Files outside the project folder
  /// are filed under 05_Exports.
  Future<void> addFiles() async {
    final picked = await FilePicker.pickFiles();
    final watcher = ref.read(fileWatcherProvider);
    final items = [...state.items];
    for (final f in picked) {
      final path = f.path;
      if (path == null || items.any((i) => i.path == path)) continue;
      var remote = watcher.relative(path);
      if (remote.startsWith('..')) remote = '05_Exports/${p.basename(path)}';
      items.add(
        UploadItem(
          path: path,
          remotePath: remote,
          size: File(path).lengthSync(),
        ),
      );
    }
    state = state.copyWith(items: items);
  }

  Future<void> upload() async {
    final session = ref.read(sessionManagerProvider);
    final project = session.project;
    if (project == null) return;
    final chosen = state.items.where((i) => i.selected).toList();
    if (chosen.isEmpty) {
      state = state.copyWith(message: () => 'Select at least one file');
      return;
    }
    state = state.copyWith(busy: true, message: () => null);
    final uploader = ref.read(uploaderProvider);
    final sub = uploader.progress.listen((u) {
      state = state.copyWith(
        items: [
          for (final i in state.items)
            i.remotePath == u.remotePath
                ? i.copyWith(state: u.state, progress: u.fraction)
                : i,
        ],
      );
    });
    try {
      final queued = await uploader.enqueue(
        projectId: project.id,
        files: [
          for (final i in chosen)
            UploadRequest(localPath: i.path, remotePath: i.remotePath),
        ],
        note: state.note,
        taskId: session.task?.id,
        completeTask: state.completeTask,
      );
      final done = await uploader.processQueue();
      final confirmed = state.items
          .where((i) => i.state == 'confirmed')
          .map((i) => i.path)
          .toList();
      ref.read(fileWatcherProvider).markUploaded(confirmed);
      final waiting = queued.queued.length - done;
      state = state.copyWith(
        busy: false,
        message: () => [
          if (done > 0) '$done file(s) uploaded.',
          if (waiting > 0) '$waiting waiting for the network; will retry.',
          if (queued.tooLarge.isNotEmpty)
            'Too large to upload: ${queued.tooLarge.join(', ')}',
        ].join(' '),
      );
    } finally {
      await sub.cancel();
    }
  }
}

final uploadControllerProvider =
    NotifierProvider<UploadController, UploadState>(UploadController.new);
