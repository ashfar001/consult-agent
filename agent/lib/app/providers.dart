import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../domain/admin_gate.dart';
import '../data/api/api_client.dart';
import '../data/api/http_api_client.dart';
import '../data/api/mock_api_client.dart';
import '../data/db/database.dart';
import '../services/auth_service.dart';
import '../services/device_info.dart';
import '../services/file_watcher.dart';
import '../services/folder_manager.dart';
import '../services/recovery_service.dart';
import '../services/uploader.dart';
import '../features/login/auth_controller.dart';
import '../services/window_service.dart';
import '../services/secure_store.dart';
import '../services/sync_worker.dart';
import '../services/win32/active_app_monitor.dart';
import '../services/win32/idle_monitor.dart';
import '../services/win32/process_lister.dart';

// Roots overridden in bootstrap (and tests).

final configProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('configProvider must be overridden'),
);

final dbProvider = Provider<AgentDatabase>(
  (ref) => throw UnimplementedError('dbProvider must be overridden'),
);

final deviceInfoProvider = Provider<DeviceInfo>(
  (ref) => throw UnimplementedError('deviceInfoProvider must be overridden'),
);

final windowServiceProvider = Provider<WindowService>(
  (ref) => throw UnimplementedError('windowServiceProvider must be overridden'),
);

/// Wall clock, injectable for tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// Derived services.

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(configProvider);
  if (config.mockApi) {
    return MockApiClient(
      latencyMs: config.mockLatencyMs,
      failureRate: config.mockFailureRate,
      random: Random(),
    );
  }
  return HttpApiClient(baseUrl: config.apiBaseUrl);
});

final secureStoreProvider = Provider<SecureStore>(
  (ref) => createSecureStore(ref.watch(dbProvider).kvDao),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    api: ref.watch(apiClientProvider),
    secureStore: ref.watch(secureStoreProvider),
    kv: ref.watch(dbProvider).kvDao,
    deviceId: ref.watch(deviceInfoProvider).deviceId,
  ),
);

/// Whether an earlier day (or an unclean session) still owes a report.
final pendingReportProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final today = DateFormat('yyyy-MM-dd').format(ref.read(clockProvider)());
    return await ref.read(dbProvider).reportDao.pendingDate(today) != null;
  },
);

// Tracking services.

final idleMonitorProvider = Provider<IdleMonitor>((ref) => createIdleMonitor());

final activeAppMonitorProvider = Provider<ActiveAppMonitor>(
  (ref) => createActiveAppMonitor(),
);

final processListerProvider = Provider<ProcessLister>(
  (ref) => createProcessLister(),
);

/// Set false in tests that drive `tick()` by hand.
final tickerEnabledProvider = Provider<bool>((ref) => true);

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(
    db: ref.watch(dbProvider),
    api: ref.watch(apiClientProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(worker.dispose);
  return worker;
});

// Files.

final folderManagerProvider = Provider<FolderManager>((ref) {
  return FolderManager(
    config: ref.watch(configProvider),
    db: ref.watch(dbProvider),
    api: ref.watch(apiClientProvider),
    currentWorkerName: ref.watch(
      authControllerProvider.select((s) => s.worker?.name),
    ),
  );
});

final fileWatcherProvider = Provider<FileWatcher>((ref) {
  final w = FileWatcher(db: ref.watch(dbProvider));
  ref.onDispose(w.dispose);
  return w;
});

final uploaderProvider = Provider<Uploader>((ref) {
  final u = Uploader(
    db: ref.watch(dbProvider),
    api: ref.watch(apiClientProvider),
    clock: ref.watch(clockProvider),
    maxFileBytes: ref.watch(configProvider).maxUploadFileBytes,
  );
  ref.onDispose(u.dispose);
  return u;
});

final recoveryServiceProvider = Provider<RecoveryService>(
  (ref) => RecoveryService(
    db: ref.watch(dbProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// True while the sync worker can reach the server.
final syncOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncWorkerProvider).onlineChanges;
});

/// Guards the super-admin exit. Demo (mock) builds with no password set
/// accept `admin1234` so the flow can be tried; real builds never do.
final adminGateProvider = Provider<AdminGate>((ref) {
  final cfg = ref.watch(configProvider);
  return AdminGate(
    hash: cfg.adminExitHash,
    salt: cfg.adminExitSalt,
    clock: ref.watch(clockProvider),
    demoPassword: cfg.mockApi && cfg.adminExitHash.isEmpty ? 'admin1234' : null,
  );
});
