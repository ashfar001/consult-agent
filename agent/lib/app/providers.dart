import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/api/http_api_client.dart';
import '../data/api/mock_api_client.dart';
import '../data/db/database.dart';
import '../services/auth_service.dart';
import '../services/device_info.dart';
import '../services/lock_service.dart';
import '../services/secure_store.dart';

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

final lockServiceProvider = Provider<LockService>(
  (ref) => throw UnimplementedError('lockServiceProvider must be overridden'),
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

/// Whether yesterday's report is still owed. Implemented in phase 4.
final pendingReportProvider = Provider<Future<bool> Function()>(
  (ref) => () async => false,
);
