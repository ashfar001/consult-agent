import 'dart:io';

import 'package:path/path.dart' as p;

/// The edge of the current display's work area that anchors the timer dock.
enum DockEdge {
  left,
  right;

  DockEdge get opposite => this == left ? right : left;
}

/// Per-Windows-user display preference, separate from the shared agent data.
class TimerDockPreferences {
  TimerDockPreferences(this._file);

  static TimerDockPreferences? forCurrentUser() {
    final env = Platform.environment;
    final base = env['LOCALAPPDATA'] ?? env['USERPROFILE'];
    return base == null || base.isEmpty
        ? null
        : TimerDockPreferences(
            File(p.join(base, 'ConsultAgent', 'timer-dock-edge')),
          );
  }

  final File _file;

  Future<DockEdge> read() async {
    if (!await _file.exists()) return DockEdge.right;
    return (await _file.readAsString()).trim() == DockEdge.left.name
        ? DockEdge.left
        : DockEdge.right;
  }

  Future<void> write(DockEdge edge) async {
    await _file.parent.create(recursive: true);
    final pending = File('${_file.path}.tmp');
    await pending.writeAsString(edge.name, flush: true);
    await pending.rename(_file.path);
  }
}
