import 'dart:math';

import 'package:consult_agent/app/providers.dart';
import 'package:consult_agent/config/app_config.dart';
import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/services/session_manager.dart';
import 'package:consult_agent/services/sync_worker.dart';
import 'package:consult_agent/services/win32/active_app_monitor.dart';
import 'package:consult_agent/services/win32/idle_monitor.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sync worker whose automatic kicks do nothing, so tests control sync.
class QuietSyncWorker extends SyncWorker {
  QuietSyncWorker({
    required super.db,
    required super.api,
    required super.clock,
  });

  @override
  void kick() {}
}

Project project({
  String id = 'p-1',
  double allocatedHours = 10,
  int usedSecs = 0,
  OverrunMode mode = OverrunMode.allow,
}) => Project(
  id: id,
  code: 'KP-1',
  name: 'Test',
  client: 'C',
  overrunMode: mode,
  folderTemplate: const [],
  myAllocatedHours: allocatedHours,
  myUsedSeconds: usedSecs,
  projectTotalHours: 50,
  projectUsedSeconds: 0,
  tasks: const [
    ProjectTask(
      id: 't-1',
      title: 'Task',
      status: TaskStatus.inProgress,
      allocatedHours: 5,
    ),
  ],
);

const task = ProjectTask(
  id: 't-1',
  title: 'Task',
  status: TaskStatus.inProgress,
  allocatedHours: 5,
);

class Harness {
  Harness(DateTime start) : now = start {
    db = AgentDatabase(NativeDatabase.memory());
    api = MockApiClient(latencyMs: 0, failureRate: 0, random: Random(1))
      ..token = 'mock-token-emp001';
    config = AppConfig.defaults(programDataDir: '/tmp', userProfileDir: '/tmp');
    worker = QuietSyncWorker(db: db, api: api, clock: () => now);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        configProvider.overrideWithValue(config),
        dbProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(api),
        clockProvider.overrideWithValue(() => now),
        tickerEnabledProvider.overrideWithValue(false),
        idleMonitorProvider.overrideWithValue(idle),
        activeAppMonitorProvider.overrideWithValue(app),
        syncWorkerProvider.overrideWithValue(worker),
      ],
    );
  }

  DateTime now;
  late final AgentDatabase db;
  late final MockApiClient api;
  late final AppConfig config;
  late final QuietSyncWorker worker;
  late final ProviderContainer container;
  final idle = FakeIdleMonitor();
  final app = FakeActiveAppMonitor(
    const ForegroundApp(exe: 'acad.exe', title: 'Drawing1.dwg'),
  );

  SessionManager get manager => container.read(sessionManagerProvider.notifier);
  SessionState get state => container.read(sessionManagerProvider);

  /// Advances the clock and ticks every 5 s for [seconds].
  Future<void> run(int seconds) async {
    for (var s = 0; s < seconds; s += 5) {
      now = now.add(const Duration(seconds: 5));
      await manager.tick();
    }
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}
