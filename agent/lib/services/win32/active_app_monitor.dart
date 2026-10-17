import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';

/// The window the user is working in.
class ForegroundApp {
  const ForegroundApp({required this.exe, required this.title});

  /// Process image name, e.g. `acad.exe` (empty if unknown).
  final String exe;
  final String title;
}

abstract interface class ActiveAppMonitor {
  ForegroundApp foreground();
}

class Win32ActiveAppMonitor implements ActiveAppMonitor {
  @override
  ForegroundApp foreground() => using((arena) {
    final hwnd = GetForegroundWindow();
    if (hwnd.address == 0) return const ForegroundApp(exe: '', title: '');

    final titleBuf = arena<Uint16>(512).cast<Utf16>();
    final titleLen = GetWindowText(hwnd, PWSTR(titleBuf), 512).value;
    final title = titleLen > 0 ? titleBuf.toDartString() : '';

    final pid = arena<Uint32>();
    GetWindowThreadProcessId(hwnd, pid);
    if (pid.value == 0) return ForegroundApp(exe: '', title: title);

    final handle = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION,
      false,
      pid.value,
    ).value;
    if (handle.address == 0) return ForegroundApp(exe: '', title: title);
    try {
      final pathBuf = arena<Uint16>(1024).cast<Utf16>();
      final size = arena<Uint32>()..value = 1024;
      final ok = QueryFullProcessImageName(
        handle,
        PROCESS_NAME_WIN32,
        PWSTR(pathBuf),
        size,
      ).value;
      final exe = ok ? p.basename(pathBuf.toDartString()) : '';
      return ForegroundApp(exe: exe, title: title);
    } finally {
      CloseHandle(handle);
    }
  });
}

class FakeActiveAppMonitor implements ActiveAppMonitor {
  FakeActiveAppMonitor([this.value = const ForegroundApp(exe: '', title: '')]);

  ForegroundApp value;

  @override
  ForegroundApp foreground() => value;
}

ActiveAppMonitor createActiveAppMonitor() =>
    Platform.isWindows ? Win32ActiveAppMonitor() : FakeActiveAppMonitor();
