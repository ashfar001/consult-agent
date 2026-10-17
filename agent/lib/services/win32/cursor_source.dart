import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Where the mouse cursor is, in logical pixels (the same units as the
/// window bounds window_manager reports).
abstract interface class CursorSource {
  Offset? position();
}

class Win32CursorSource implements CursorSource {
  @override
  Offset? position() => using((arena) {
    final point = arena<POINT>();
    if (!GetCursorPos(point).value) return null;
    final dpr = PlatformDispatcher.instance.views.isEmpty
        ? 1.0
        : PlatformDispatcher.instance.views.first.devicePixelRatio;
    return Offset(point.ref.x / dpr, point.ref.y / dpr);
  });
}

class FakeCursorSource implements CursorSource {
  FakeCursorSource([this.value]);

  Offset? value;

  @override
  Offset? position() => value;
}

CursorSource createCursorSource() =>
    Platform.isWindows ? Win32CursorSource() : FakeCursorSource();
