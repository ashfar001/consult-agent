import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Seconds since the last keyboard or mouse input.
abstract interface class IdleMonitor {
  int idleSecs();
}

class Win32IdleMonitor implements IdleMonitor {
  @override
  int idleSecs() => using((arena) {
        final info = arena<LASTINPUTINFO>();
        info.ref.cbSize = sizeOf<LASTINPUTINFO>();
        if (!GetLastInputInfo(info)) return 0;
        // Both values are 32-bit tick counts that wrap together.
        final diff = (GetTickCount() - info.ref.dwTime) & 0xFFFFFFFF;
        return diff ~/ 1000;
      });
}

/// Scriptable monitor for tests and non-Windows hosts.
class FakeIdleMonitor implements IdleMonitor {
  FakeIdleMonitor([this.value = 0]);

  int value;

  @override
  int idleSecs() => value;
}

IdleMonitor createIdleMonitor() =>
    Platform.isWindows ? Win32IdleMonitor() : FakeIdleMonitor();
