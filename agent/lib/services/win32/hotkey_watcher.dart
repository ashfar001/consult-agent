import 'dart:async';
import 'dart:io';

import 'package:win32/win32.dart';

/// Fires when Ctrl+Shift+F12 is pressed anywhere in Windows, even while the
/// agent window is hidden. Polls key state, so it needs no native code and
/// does not swallow the keys.
class HotkeyWatcher {
  HotkeyWatcher({
    this.pollInterval = const Duration(milliseconds: 150),
    bool Function()? isPressed,
  }) : _isPressed = isPressed ?? _comboPressed;

  final Duration pollInterval;
  final bool Function() _isPressed;
  final _controller = StreamController<void>.broadcast();
  Timer? _timer;
  bool _wasDown = false;

  Stream<void> get pressed => _controller.stream;

  static bool _down(int vk) => (GetAsyncKeyState(vk) & 0x8000) != 0;

  static bool _comboPressed() {
    if (!Platform.isWindows) return false;
    return _down(VK_CONTROL) && _down(VK_SHIFT) && _down(VK_F12);
  }

  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => check());
  }

  /// One poll; fires once per press, not while held.
  void check() {
    final down = _isPressed();
    if (down && !_wasDown) _controller.add(null);
    _wasDown = down;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }
}
