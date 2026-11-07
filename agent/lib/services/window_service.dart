import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'bar_hide_logic.dart';
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

  /// The timer bar's current rectangle (null if it isn't showing).
  Future<Rect?> barBounds();

  /// Resizes the bar to a thin strip at the top edge, or expands it again.
  Future<void> setBarCollapsed(bool collapsed);

  Future<void> exitApp();
}

/// window_manager-backed service. The PC is never locked: the window is
/// hidden unless the agent needs the worker's attention.
class DesktopWindowService implements WindowService {
  WindowMode _mode = WindowMode.hidden;
  static const _barChannel = MethodChannel('consult_agent/timer_bar');
  static const _barWidth = 400.0;
  static const _barHeight = 104.0;

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
    final previousMode = _mode;
    _mode = mode;
    try {
      if (previousMode == WindowMode.bar && mode != WindowMode.bar) {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      }
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
        await windowManager.setAsFrameless();
        await windowManager.setResizable(false);
        await windowManager.setMinimumSize(
          const Size(100, timerBarStripHeight),
        );
        await _resizeBar(_barHeight, center: true);
        await windowManager.setSkipTaskbar(true);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.show();
        await windowManager.focus();
    }
  }

  @override
  Future<Rect?> barBounds() async =>
      _mode == WindowMode.bar ? await windowManager.getBounds() : null;

  @override
  Future<void> setBarCollapsed(bool collapsed) async {
    if (_mode != WindowMode.bar) return;
    await _resizeBar(collapsed ? timerBarStripHeight : _barHeight);
  }

  Future<void> _resizeBar(double height, {bool center = false}) async {
    if (Platform.isWindows) {
      await _barChannel.invokeMethod<void>('resize', [
        _barWidth.toInt(),
        height.toInt(),
        center,
      ]);
      return;
    }
    await windowManager.setSize(Size(_barWidth, height));
    if (center) await windowManager.setAlignment(Alignment.topCenter);
  }

  Future<void> _show(Size size, {required Alignment alignment}) async {
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const Size(100, 40));
    await windowManager.setSize(size);
    await windowManager.setResizable(false);
    await windowManager.setAlignment(alignment);
    await windowManager.setSkipTaskbar(false);
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
  bool _collapsed = false;
  bool exited = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMode(WindowMode mode) async {
    modes.add(mode);
    _collapsed = false;
  }

  @override
  Future<Rect?> barBounds() async => modes.lastOrNull == WindowMode.bar
      ? Rect.fromLTWH(500, 0, 400, _collapsed ? timerBarStripHeight : 104)
      : null;

  @override
  Future<void> setBarCollapsed(bool collapsed) async {
    collapses.add(collapsed);
    _collapsed = collapsed;
  }

  @override
  Future<void> exitApp() async => exited = true;
}
