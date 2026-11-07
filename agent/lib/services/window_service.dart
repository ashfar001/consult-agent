import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'bar_hide_logic.dart';
import 'logging.dart';
import 'timer_dock_preferences.dart';

/// What the single agent window currently looks like.
enum WindowMode {
  /// Not visible; the agent just tracks and watches for CAD apps.
  hidden,

  /// Large window for sign-in and project selection.
  prompt,

  /// Small always-on-top edge dock.
  bar,

  /// Small centred window for break, overtime and notices.
  small,

  /// Large window for upload, End Work and Summary.
  dialog,
}

typedef DockInput = ({bool pointerInside, bool keyboardFocus});

abstract interface class WindowService {
  Future<void> init();
  Future<void> setMode(WindowMode mode);

  ValueListenable<DockEdge> get dockEdge;
  Future<void> moveDock(DockEdge edge);

  /// Native input state for the actual dock rectangle, or null outside dock mode.
  Future<DockInput?> dockInput();

  /// Hover expands without activation; an explicit hotkey can request focus.
  Future<void> setBarCollapsed(bool collapsed, {bool focus = false});

  Future<void> exitApp();
}

/// WindowManager handles dialogs; the Windows runner owns the dock's exact
/// bounds and no-activate show/resize on the same top-level window.
class DesktopWindowService implements WindowService {
  WindowMode _mode = WindowMode.hidden;
  static const _barChannel = MethodChannel('consult_agent/timer_bar');
  final _dockEdge = ValueNotifier(DockEdge.right);
  final _preferences = TimerDockPreferences.forCurrentUser();
  bool _collapsed = true;

  @override
  ValueListenable<DockEdge> get dockEdge => _dockEdge;

  @override
  Future<void> init() async {
    try {
      _dockEdge.value = await _preferences?.read() ?? DockEdge.right;
    } on FileSystemException catch (e, st) {
      log.w('Could not read timer dock preference', error: e, stackTrace: st);
    }
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
        if (Platform.isWindows) {
          await _barChannel.invokeMethod<void>('leave');
        } else {
          await windowManager.hide();
        }
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      }
      await _apply(mode);
    } on Object catch (e, st) {
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
        // A dialog may own focus. Hide it before switching to the passive dock.
        await windowManager.hide();
        await windowManager.setAsFrameless();
        await windowManager.setResizable(false);
        await windowManager.setMinimumSize(
          const Size(timerDockTabWidth, timerDockHeight),
        );
        await windowManager.setSkipTaskbar(true);
        _collapsed = true;
        if (Platform.isWindows) {
          // window_manager's Windows implementation activates even when passed
          // inactive: true. Show the dock directly in the runner instead.
          await _barChannel.invokeMethod<void>('enter', _dockEdge.value.name);
        } else {
          await windowManager.setAlwaysOnTop(true);
          await _placeFallback();
          await windowManager.show(inactive: true);
        }
    }
  }

  @override
  Future<void> moveDock(DockEdge edge) async {
    if (_mode != WindowMode.bar || _dockEdge.value == edge) return;
    if (Platform.isWindows) {
      await _barChannel.invokeMethod<void>('move', edge.name);
    } else {
      await _placeFallback(edge);
    }
    _dockEdge.value = edge;
    try {
      await _preferences?.write(edge);
    } on FileSystemException catch (e, st) {
      log.w('Could not save timer dock preference', error: e, stackTrace: st);
    }
  }

  @override
  Future<DockInput?> dockInput() async {
    if (_mode != WindowMode.bar) return null;
    if (!Platform.isWindows) {
      return (
        pointerInside: false,
        keyboardFocus: await windowManager.isFocused(),
      );
    }
    final input = await _barChannel.invokeListMethod<bool>('input');
    if (input == null) return null;
    return (pointerInside: input[0], keyboardFocus: input[1]);
  }

  @override
  Future<void> setBarCollapsed(bool collapsed, {bool focus = false}) async {
    if (_mode != WindowMode.bar) return;
    if (Platform.isWindows) {
      await _barChannel.invokeMethod<void>(collapsed ? 'collapse' : 'expand');
    } else {
      await _placeFallback(null, collapsed);
    }
    _collapsed = collapsed;
    if (focus) await windowManager.focus();
  }

  Future<void> _placeFallback([DockEdge? edge, bool? collapsed]) async {
    await windowManager.setSize(
      Size(
        (collapsed ?? _collapsed) ? timerDockTabWidth : timerDockWidth,
        timerDockHeight,
      ),
    );
    await windowManager.setAlignment(
      (edge ?? _dockEdge.value) == DockEdge.left
          ? Alignment.centerLeft
          : Alignment.centerRight,
    );
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

/// Records modes and focus requests instead of touching a native window.
class FakeWindowService implements WindowService {
  final List<WindowMode> modes = [];
  final List<bool> collapses = [];
  final _dockEdge = ValueNotifier(DockEdge.right);
  bool pointerInside = false;
  bool keyboardFocus = false;
  int focusRequests = 0;
  bool exited = false;

  @override
  ValueListenable<DockEdge> get dockEdge => _dockEdge;

  @override
  Future<void> init() async {}

  @override
  Future<void> setMode(WindowMode mode) async => modes.add(mode);

  @override
  Future<void> moveDock(DockEdge edge) async => _dockEdge.value = edge;

  @override
  Future<DockInput?> dockInput() async => modes.lastOrNull == WindowMode.bar
      ? (pointerInside: pointerInside, keyboardFocus: keyboardFocus)
      : null;

  @override
  Future<void> setBarCollapsed(bool collapsed, {bool focus = false}) async {
    collapses.add(collapsed);
    if (focus) focusRequests++;
  }

  @override
  Future<void> exitApp() async => exited = true;
}
