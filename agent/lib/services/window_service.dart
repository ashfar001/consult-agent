import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:window_manager/window_manager.dart';

import 'logging.dart';

/// What the single agent window currently looks like.
enum WindowMode {
  /// Not visible; the agent just tracks and watches for CAD apps.
  hidden,

  /// Large window for sign-in and project selection.
  prompt,

  /// Small always-on-top timer strip.
  bar,

  /// Small centred window for break, overtime and notices.
  small,

  /// Large window for upload, End Work and Summary.
  dialog,
}

abstract interface class WindowService {
  Future<void> init();
  Future<void> setMode(WindowMode mode);

  /// The timer bar's rectangle when expanded (null if it isn't showing).
  Future<Rect?> barBounds();

  /// Slides the bar up so only a thin strip shows, or back down.
  Future<void> setBarCollapsed(bool collapsed);

  Future<void> exitApp();
}

/// window_manager-backed service. The PC is never locked: the window is
/// hidden unless the agent needs the worker's attention.
class DesktopWindowService implements WindowService {
  WindowMode _mode = WindowMode.hidden;
  Rect? _bar;

  /// Height of the strip that stays visible when the bar is collapsed.
  static const stripHeight = 6.0;

  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'ConsultAgent',
        titleBarStyle: TitleBarStyle.hidden,
        backgroundColor: Color(0xFFF5F6F8),
        skipTaskbar: true,
      ),
    );
    // Alt+F4 must not kill the agent mid-session.
    await windowManager.setPreventClose(true);
    await setMode(WindowMode.hidden);
  }

  @override
  Future<void> setMode(WindowMode mode) async {
    _mode = mode;
    _bar = null;
    try {
      await _apply(mode);
    } on Object catch (e, st) {
      // A window hiccup must never leave the app stuck on the wrong screen.
      log.e('Window mode ${mode.name} failed', error: e, stackTrace: st);
    }
    log.d('Window mode: ${_mode.name}');
  }

  Future<void> _apply(WindowMode mode) async {
    switch (mode) {
      case WindowMode.hidden:
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setSkipTaskbar(true);
        await windowManager.hide();
      case WindowMode.prompt:
        await _show(const Size(1040, 780), alignment: Alignment.center);
      case WindowMode.small:
        await _show(const Size(520, 340), alignment: Alignment.center);
      case WindowMode.dialog:
        await _show(const Size(940, 760), alignment: Alignment.center);
      case WindowMode.bar:
        await _show(
          const Size(400, 56),
          alignment: Alignment.topCenter,
          taskbar: false,
        );
        _bar = await windowManager.getBounds();
    }
  }

  @override
  Future<Rect?> barBounds() async => _bar;

  @override
  Future<void> setBarCollapsed(bool collapsed) async {
    final b = _bar;
    if (b == null || _mode != WindowMode.bar) return;
    final y = collapsed ? b.top - (b.height - stripHeight) : b.top;
    await windowManager.setPosition(Offset(b.left, y));
  }

  Future<void> _show(
    Size size, {
    required Alignment alignment,
    bool taskbar = true,
  }) async {
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const Size(100, 40));
    await windowManager.setSize(size);
    await windowManager.setResizable(false);
    await windowManager.setAlignment(alignment);
    await windowManager.setSkipTaskbar(!taskbar);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> exitApp() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
    exit(0);
  }
}

/// Records modes instead of touching a window (tests).
class FakeWindowService implements WindowService {
  final List<WindowMode> modes = [];
  final List<bool> collapses = [];
  bool exited = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMode(WindowMode mode) async => modes.add(mode);

  @override
  Future<Rect?> barBounds() async => const Rect.fromLTWH(500, 0, 400, 56);

  @override
  Future<void> setBarCollapsed(bool collapsed) async =>
      collapses.add(collapsed);

  @override
  Future<void> exitApp() async => exited = true;
}
