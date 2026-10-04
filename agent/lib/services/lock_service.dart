import 'dart:async';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'logging.dart';

/// Controls the agent window's two modes: the fullscreen lock (login,
/// project select, pause, pending report) and the unlocked state.
abstract interface class LockService {
  bool get isLocked;
  Future<void> init();
  Future<void> enterLockMode();
  Future<void> exitLockMode();
}

/// window_manager-based lock. The low-level keyboard hook that swallows
/// Win/Alt+Tab etc. is added in phase 5 on the `agent/lock` channel.
class WindowLockService with WindowListener implements LockService {
  WindowLockService({MethodChannel? hookChannel})
      : _hookChannel = hookChannel ?? const MethodChannel('agent/lock');

  final MethodChannel _hookChannel;
  bool _locked = false;
  Timer? _refocusDebounce;

  @override
  bool get isLocked => _locked;

  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'ConsultAgent',
        titleBarStyle: TitleBarStyle.hidden,
        backgroundColor: Color(0xFFF5F6F8),
        skipTaskbar: true,
      ),
    );
    await windowManager.setPreventClose(true);
    await windowManager.show();
  }

  @override
  Future<void> enterLockMode() async {
    _locked = true;
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
    await _setHook(true);
    log.i('Lock mode entered');
  }

  @override
  Future<void> exitLockMode() async {
    _locked = false;
    await _setHook(false);
    await windowManager.setFullScreen(false);
    await windowManager.setMinimizable(true);
    log.i('Lock mode exited');
  }

  Future<void> _setHook(bool enable) async {
    try {
      await _hookChannel.invokeMethod<void>(
        enable ? 'enableHook' : 'disableHook',
      );
    } on MissingPluginException {
      // Native hook not registered yet (phase 5).
    } on PlatformException catch (e) {
      log.w('Keyboard hook ${enable ? 'enable' : 'disable'} failed: $e');
    }
  }

  @override
  void onWindowBlur() {
    if (!_locked) return;
    // Re-assert focus shortly after losing it, so a stray click or popup
    // cannot leave the desktop usable while locked.
    _refocusDebounce?.cancel();
    _refocusDebounce = Timer(const Duration(milliseconds: 150), () async {
      if (!_locked) return;
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  void onWindowClose() {
    // Prevent-close is on: closing is only possible via the agent itself.
    log.w('Window close requested; ignored');
  }
}

/// No-op lock for tests.
class FakeLockService implements LockService {
  @override
  bool isLocked = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> enterLockMode() async => isLocked = true;

  @override
  Future<void> exitLockMode() async => isLocked = false;
}
