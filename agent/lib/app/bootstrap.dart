import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../config/config_loader.dart';
import '../data/db/daos.dart';
import '../data/db/database.dart';
import '../services/device_info.dart';
import '../services/lock_service.dart';
import '../services/logging.dart';
import 'app.dart';
import 'providers.dart';

/// Starts the agent: dirs, logging, config, DB, device id, window, app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final loader = ConfigLoader();
  var config = loader.load();
  config = _withWritableDirs(config, loader.userProfileDir);

  await initLogging(config.logDir);
  for (final w in loader.warnings) {
    log.w(w);
  }
  log.i('ConsultAgent starting (mock=${config.mockApi}, '
      'data=${config.dataDir})');

  FlutterError.onError = (details) {
    log.e('Flutter error', error: details.exception, stackTrace: details.stack);
  };

  final db = AgentDatabase.open(config.dataDir);
  final deviceId = await db.kvDao
      .getOrCreate(KvDao.deviceIdKey, () => const Uuid().v4());
  final device = DeviceInfo(
    deviceId: deviceId,
    pcName: DeviceInfo.currentPcName(),
  );

  final lock = WindowLockService();
  await lock.init();
  await lock.enterLockMode();

  runApp(
    ProviderScope(
      // Failures are surfaced by controllers; never auto-retry silently.
      retry: (_, _) => null,
      overrides: [
        configProvider.overrideWithValue(config),
        dbProvider.overrideWithValue(db),
        deviceInfoProvider.overrideWithValue(device),
        lockServiceProvider.overrideWithValue(lock),
      ],
      child: const ConsultAgentApp(),
    ),
  );
}

/// Standard users may lack write access to ProgramData; fall back to a
/// per-user location so the agent (and its time data) always has a DB.
AppConfig _withWritableDirs(AppConfig config, String userProfileDir) {
  bool writable(String dir) {
    try {
      Directory(dir).createSync(recursive: true);
      final probe = File(p.join(dir, '.write_probe'));
      probe.writeAsStringSync('ok');
      probe.deleteSync();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  final fallbackBase = p.join(
    Platform.environment['LOCALAPPDATA'] ?? userProfileDir,
    'ConsultAgent',
  );
  return config.mergeJson({
    if (!writable(config.dataDir)) 'data_dir': p.join(fallbackBase, 'data'),
    if (!writable(config.logDir)) 'log_dir': p.join(fallbackBase, 'logs'),
  });
}
