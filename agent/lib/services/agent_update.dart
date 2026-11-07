import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'agent_release.dart';
import 'logging.dart';
import 'win32/agent_executable.dart';

/// Coordinates the download and the bundled installer. The helper stages and
/// validates the package while the current app is still running.
class AgentUpdateService {
  AgentUpdateService({required this.protectedPaths});

  static const _asset = 'assets/updater/install.ps1';
  static const _startupSignal = 'CONSULT_AGENT_UPDATE_STARTUP_SIGNAL';

  final List<String> protectedPaths;
  final _client = AgentReleaseClient();

  String get _executable => Platform.resolvedExecutable;

  Directory get _temp {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local == null || local.isEmpty || !p.isAbsolute(local)) {
      throw const UpdateException(
        'The Windows user update folder is unavailable.',
      );
    }
    return Directory(p.join(local, 'ConsultAgentUpdater'));
  }

  File get _result {
    final key = sha256.convert(
      utf8.encode(p.normalize(_executable).toLowerCase()),
    );
    return File(p.join(_temp.path, '$key.error'));
  }

  Future<AgentRelease?> check() {
    requireUnelevatedUpdater();
    return _client.latest(windowsAgentVersion(_executable));
  }

  void openReleasesPage() => openAgentReleasesPage();

  /// Acknowledge reaching the startup sign-in screen after a helper restart.
  /// Write only inside the per-user directory used for this handoff.
  void acknowledgeStartup() {
    final signal = Platform.environment[_startupSignal];
    if (signal == null) return;
    final operation = p.dirname(signal);
    try {
      if (p.basename(signal) == 'started' &&
          p.basename(operation).startsWith('operation-') &&
          p.equals(p.dirname(operation), _temp.path)) {
        File(signal).writeAsStringSync('$pid', flush: true);
      }
    } on FileSystemException catch (error) {
      log.w('Could not acknowledge update startup', error: error);
    } on UpdateException catch (error) {
      log.w('Could not acknowledge update startup', error: error);
    }
  }

  String? takePreviousFailure() {
    try {
      final file = _result;
      if (!file.existsSync()) return null;
      final message = file.readAsStringSync().trim();
      file.deleteSync();
      return message.isEmpty ? null : message;
    } on FileSystemException catch (error) {
      log.w('Could not read the previous update result', error: error);
      return null;
    } on UpdateException {
      return null;
    }
  }

  Future<PreparedAgentUpdate> prepare(
    AgentRelease release,
    void Function(double?) onProgress,
  ) async {
    requireUnelevatedUpdater();
    final temp = _temp;
    final installDir = p.dirname(_executable);
    if (p.equals(temp.path, installDir) || p.isWithin(installDir, temp.path)) {
      throw const UpdateException(
        'This app is installed in a Windows data folder. Use the releases page to update it manually.',
      );
    }
    await temp.create(recursive: true);
    final work = await temp.createTemp('operation-');
    final pending = PreparedAgentUpdate._(work);
    var helperStarted = false;
    try {
      final archive = File(p.join(work.path, 'release.zip'));
      await _client.download(release, archive, onProgress);
      onProgress(null);

      final script = await rootBundle.loadString(_asset);
      final helper = File(p.join(work.path, 'install.ps1'));
      await helper.writeAsString(script, flush: true);
      final paths = await _protectedLocations();
      await File(p.join(work.path, 'handoff.json')).writeAsString(
        jsonEncode({
          'executable': _executable,
          'processId': pid,
          'version': release.version.toString(),
          'sha256': release.sha256Hex,
          'resultFile': _result.path,
          'protectedPaths': paths,
        }),
        flush: true,
      );

      final systemRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
      final powershell = p.join(
        systemRoot,
        'System32',
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe',
      );
      await Process.start(
        powershell,
        [
          '-NoProfile',
          '-NonInteractive',
          '-WindowStyle',
          'Hidden',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          helper.path,
        ],
        workingDirectory: systemRoot,
        mode: ProcessStartMode.detached,
      );
      helperStarted = true;
      await pending._waitUntilReady();
      return pending;
    } on Object {
      try {
        if (helperStarted) {
          pending.cancel();
        } else {
          await work.delete(recursive: true);
        }
      } on FileSystemException catch (error) {
        log.w('Could not clean up update download', error: error);
      }
      rethrow;
    }
  }

  Future<List<String>> _protectedLocations() async {
    final local = Platform.environment['LOCALAPPDATA']!;
    final programData =
        Platform.environment['ProgramData'] ?? r'C:\ProgramData';
    final locations = {
      p.join(local, 'ConsultAgent'),
      p.join(programData, 'ConsultAgent'),
      _temp.path,
      ...protectedPaths.where((path) => path.isNotEmpty).map(p.absolute),
    };
    for (final location in locations.toList()) {
      try {
        locations.add(await Directory(location).resolveSymbolicLinks());
      } on FileSystemException {
        // Keep the original path, including configured locations not yet made.
      }
    }
    return locations.toList();
  }
}

class PreparedAgentUpdate {
  PreparedAgentUpdate._(this._work);

  final Directory _work;

  File _file(String name) => File(p.join(_work.path, name));

  Future<void> _waitUntilReady() async {
    final stopwatch = Stopwatch()..start();
    final ready = _file('ready');
    final error = _file('prepare-error');
    while (stopwatch.elapsed < const Duration(minutes: 2)) {
      if (await error.exists()) {
        final message = (await error.readAsString()).trim();
        if (message.isNotEmpty) throw UpdateException(message);
      }
      if (await ready.exists()) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw const UpdateException(
      'Windows could not prepare the update. Use the releases page if the problem continues.',
    );
  }

  void commit() => _file('commit').writeAsStringSync('install', flush: true);

  void cancel() => _file('cancel').writeAsStringSync('cancel', flush: true);
}
