import 'dart:convert';
import 'dart:io';

import 'package:consult_agent/config/config_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('ca_cfg'));
  tearDown(() => tmp.deleteSync(recursive: true));

  ConfigLoader loader({Map<String, String> env = const {}, bool mock = false}) =>
      ConfigLoader(
        programDataDir: tmp.path,
        userProfileDir: p.join(tmp.path, 'user'),
        environment: env,
        mockDefine: mock,
      );

  test('missing file gives defaults and writes a sample', () {
    final l = loader();
    final c = l.load();
    expect(c.idleThresholdSecs, 300);
    expect(c.heartbeatIntervalSecs, 60);
    expect(c.pollIntervalSecs, 5);
    expect(c.mockApi, isFalse);
    expect(c.projectsRoot, r'D:\Projects');
    expect(c.fallbackProjectsRoot, p.join(tmp.path, 'user', 'Projects'));
    expect(c.dataDir, p.join(tmp.path, 'ConsultAgent', 'data'));
    expect(File(l.configPath).existsSync(), isTrue);
  });

  test('file values override defaults; unknown/invalid types ignored', () {
    final file = File(p.join(tmp.path, 'ConsultAgent', 'config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'company_name': 'Acme Consultants',
        'idle_threshold_secs': 120,
        'mock_failure_rate': 0, // int where double expected
        'heartbeat_interval_secs': 'sixty', // wrong type, ignored
        'unknown': true,
      }));
    final c = loader().load();
    expect(file.existsSync(), isTrue);
    expect(c.companyName, 'Acme Consultants');
    expect(c.idleThresholdSecs, 120);
    expect(c.mockFailureRate, 0.0);
    expect(c.heartbeatIntervalSecs, 60);
  });

  test('malformed file falls back to defaults with a warning', () {
    File(p.join(tmp.path, 'ConsultAgent', 'config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');
    final l = loader();
    final c = l.load();
    expect(c.idleThresholdSecs, 300);
    expect(l.warnings, isNotEmpty);
  });

  test('MOCK_API env var or dart-define enables mock mode', () {
    expect(loader(env: {'MOCK_API': 'true'}).load().mockApi, isTrue);
    expect(loader(env: {'MOCK_API': '1'}).load().mockApi, isTrue);
    expect(loader(mock: true).load().mockApi, isTrue);
    expect(loader(env: {'MOCK_API': 'false'}).load().mockApi, isFalse);
  });
}
