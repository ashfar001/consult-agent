import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../domain/file_rules.dart';

/// Files the worker created or changed in a project folder.
///
/// The set is rebuilt from disk on [start] (anything newer than its synced
/// baseline, or not synced at all) and kept current from live watch events,
/// so it survives restarts.
class FileWatcher {
  FileWatcher({required this.db});

  final AgentDatabase db;

  final _changed = <String>{};
  final _controller = StreamController<Set<String>>.broadcast();
  StreamSubscription<FileSystemEvent>? _sub;
  late String _folder;

  Stream<Set<String>> get changes => _controller.stream;

  /// Absolute paths changed so far, sorted.
  List<String> get changedFiles => _changed.toList()..sort();

  Future<void> start(String projectId, String folder) async {
    await stop();
    _folder = folder;
    _changed.clear();
    final dir = Directory(folder);
    if (!dir.existsSync()) return;

    final baseline = {
      for (final v in await db.fileDao.forProject(projectId)) v.path: v.syncedAt,
    };
    for (final e in dir.listSync(recursive: true, followLinks: false)) {
      if (e is! File || isIgnoredFile(e.path)) continue;
      final rel = p.relative(e.path, from: folder).replaceAll(r'\', '/');
      final synced = baseline[rel];
      if (synced == null || e.lastModifiedSync().isAfter(synced)) {
        _changed.add(e.path);
      }
    }
    _emit();

    _sub = dir.watch(recursive: true).listen((event) {
      if (event.isDirectory || isIgnoredFile(event.path)) return;
      if (event.type == FileSystemEvent.delete) {
        _changed.remove(event.path);
      } else if (File(event.path).existsSync() &&
          !event.path.endsWith('.part')) {
        _changed.add(event.path);
      }
      _emit();
    }, onError: (Object _) {});
  }

  /// Path relative to the project folder, with forward slashes.
  String relative(String absolute) =>
      p.relative(absolute, from: _folder).replaceAll(r'\', '/');

  void markUploaded(Iterable<String> paths) {
    _changed.removeAll(paths);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add({..._changed});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
