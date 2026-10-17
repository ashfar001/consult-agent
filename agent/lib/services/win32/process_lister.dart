import 'dart:io';

/// Names of the processes currently running (lower-cased).
abstract interface class ProcessLister {
  Future<Set<String>> running();
}

/// Uses `tasklist`, which needs no elevation and works for standard users.
class TasklistProcessLister implements ProcessLister {
  @override
  Future<Set<String>> running() async {
    try {
      final r = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
      if (r.exitCode != 0) return {};
      final names = <String>{};
      for (final line in (r.stdout as String).split('\n')) {
        final t = line.trim();
        if (!t.startsWith('"')) continue;
        final end = t.indexOf('"', 1);
        if (end > 1) names.add(t.substring(1, end).toLowerCase());
      }
      return names;
    } on ProcessException {
      return {};
    }
  }
}

class FakeProcessLister implements ProcessLister {
  FakeProcessLister([Set<String>? initial]) : names = initial ?? {};

  Set<String> names;

  @override
  Future<Set<String>> running() async => {...names};
}

ProcessLister createProcessLister() =>
    Platform.isWindows ? TasklistProcessLister() : FakeProcessLister();
