import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

/// App-wide logger. Replaced in [initLogging]; usable before that (console).
Logger log = Logger(printer: SimplePrinter(printTime: true));

/// Size-rotated log files: agent.log, agent.1.log … agent.{maxFiles-1}.log.
class RotatingFileOutput extends LogOutput {
  RotatingFileOutput({
    required this.dir,
    this.baseName = 'agent',
    this.maxBytes = 5 * 1024 * 1024,
    this.maxFiles = 5,
  });

  final String dir;
  final String baseName;
  final int maxBytes;
  final int maxFiles;

  RandomAccessFile? _raf;

  String _path(int i) =>
      p.join(dir, i == 0 ? '$baseName.log' : '$baseName.$i.log');

  @override
  Future<void> init() async {
    Directory(dir).createSync(recursive: true);
    _open();
  }

  void _open() {
    _raf = File(_path(0)).openSync(mode: FileMode.append);
  }

  void _rotate() {
    _raf?.closeSync();
    final oldest = File(_path(maxFiles - 1));
    if (oldest.existsSync()) oldest.deleteSync();
    for (var i = maxFiles - 2; i >= 0; i--) {
      final f = File(_path(i));
      if (f.existsSync()) f.renameSync(_path(i + 1));
    }
    _open();
  }

  @override
  void output(OutputEvent event) {
    final raf = _raf;
    if (raf == null) return;
    try {
      raf.writeStringSync('${event.lines.join('\n')}\n');
      raf.flushSync();
      if (raf.lengthSync() >= maxBytes) _rotate();
    } on FileSystemException {
      // Logging must never crash the agent.
    }
  }

  @override
  Future<void> destroy() async {
    await _raf?.close();
    _raf = null;
  }
}

Future<void> initLogging(String logDir) async {
  final file = RotatingFileOutput(dir: logDir);
  log = Logger(
    filter: ProductionFilter(),
    level: Level.debug,
    printer: SimplePrinter(printTime: true, colors: false),
    output: MultiOutput([ConsoleOutput(), file]),
  );
  await log.init;
}
