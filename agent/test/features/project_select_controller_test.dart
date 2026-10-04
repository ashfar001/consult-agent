import 'dart:math';

import 'package:consult_agent/app/providers.dart';
import 'package:consult_agent/config/app_config.dart';
import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/features/project_select/project_select_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgentDatabase db;
  late MockApiClient api;
  late ProviderContainer container;
  final now = DateTime(2026, 10, 4, 9);

  setUp(() async {
    db = AgentDatabase(NativeDatabase.memory());
    api = MockApiClient(latencyMs: 0, failureRate: 0, random: Random(1));
    api.token = (await api.login(
      employeeId: 'EMP001',
      pin: '1234',
      deviceId: 'd',
    ))
        .token;
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        configProvider.overrideWithValue(
          AppConfig.defaults(programDataDir: '/tmp', userProfileDir: '/tmp'),
        ),
        dbProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(api),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ProjectSelectController controller() =>
      container.read(projectSelectControllerProvider.notifier);
  ProjectSelectState state() => container.read(projectSelectControllerProvider);

  test('online load shows projects and caches them', () async {
    await controller().load();
    expect(state().projects, hasLength(3));
    expect(state().offline, isFalse);
    expect((await db.projectCacheDao.load()).projects, hasLength(3));
  });

  test('offline load falls back to the cached list', () async {
    await controller().load();
    api.offline = true;
    await controller().load();
    expect(state().offline, isTrue);
    expect(state().projects, hasLength(3));
    expect(state().fetchedAt, now);
    expect(state().error, isNull);
  });

  test('offline with empty cache shows an error', () async {
    api.offline = true;
    await controller().load();
    expect(state().projects, isEmpty);
    expect(state().error, isNotNull);
  });

  test('selection and start rules', () async {
    await controller().load();
    expect(controller().startBlock(), StartBlock.noProject);

    controller().selectProject('p-101');
    expect(controller().startBlock(), StartBlock.noTask);
    controller().selectTask('t-1012');
    expect(controller().startBlock(), isNull);
    final sel = controller().selection()!;
    expect(sel.project.code, 'KP-101');
    expect(sel.task.id, 't-1012');
  });

  test('block-mode project at 100% cannot be started', () async {
    await controller().load();
    // Use up KP-103's remaining 5 minutes.
    final sid = await api.startSession(
      clientId: 'c',
      projectId: 'p-103',
      taskId: 't-1031',
      startedAt: now,
    );
    await api.sendHeartbeats([_hb(sid, now, 300)]);
    await controller().load();
    controller().selectProject('p-103');
    controller().selectTask('t-1031');
    expect(controller().startBlock(), StartBlock.hoursExhausted);
    expect(controller().selection(), isNull);
  });

  test('non-network API errors are not reported as offline', () async {
    api.token = null; // -> 401
    await controller().load();
    expect(state().offline, isFalse);
    expect(state().error, isNotNull);
  });
}

Heartbeat _hb(String sessionId, DateTime at, int active) => Heartbeat(
      clientId: 'hb-$sessionId-${at.millisecondsSinceEpoch}',
      sessionId: sessionId,
      from: at,
      to: at.add(Duration(seconds: active)),
      activeSecs: active,
      idleSecs: 0,
      apps: const {},
    );
