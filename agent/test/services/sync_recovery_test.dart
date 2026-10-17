import 'dart:convert';
import 'dart:math';

import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/services/recovery_service.dart';
import 'package:consult_agent/services/sync_worker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  late AgentDatabase db;
  late MockApiClient api;
  late SyncWorker worker;
  var now = DateTime(2026, 10, 5, 9);

  setUp(() async {
    now = DateTime(2026, 10, 5, 9);
    db = AgentDatabase(NativeDatabase.memory());
    api = MockApiClient(latencyMs: 0, failureRate: 0, random: Random(1));
    api.token = (await api.login(
      employeeId: 'EMP001',
      pin: '1234',
      deviceId: 'd',
    )).token;
    worker = SyncWorker(db: db, api: api, clock: () => now, random: Random(1));
  });

  tearDown(() async {
    worker.dispose();
    await db.close();
  });

  Future<void> localSession(String id, {int heartbeats = 2}) async {
    await db.sessionDao.insertSession(
      SessionsCompanion.insert(
        localId: id,
        workerId: 'w-1',
        projectId: 'p-101',
        taskId: 't-1011',
        startedAt: now,
        status: 'open',
      ),
    );
    await db.outboxDao.enqueue(
      clientId: id,
      kind: OutboxKind.sessionStart,
      payload: {
        'client_id': id,
        'project_id': 'p-101',
        'task_id': 't-1011',
        'started_at': isoUtc(now),
      },
      now: now,
    );
    for (var i = 0; i < heartbeats; i++) {
      await db.sessionDao.insertHeartbeat(
        HeartbeatsCompanion.insert(
          clientId: '$id-hb$i',
          localSessionId: id,
          fromTime: now.add(Duration(minutes: i)),
          toTime: now.add(Duration(minutes: i + 1)),
          activeSecs: 50,
          idleSecs: 10,
          appsJson: jsonEncode({'AutoCAD': 50}),
        ),
      );
    }
  }

  test('a pass sends start, heartbeats and stop in order', () async {
    await localSession('s1');
    await db.sessionDao.closeSession('s1', endedAt: now, status: 'closed');
    await db.outboxDao.enqueue(
      clientId: 'stop-s1',
      kind: OutboxKind.sessionStop,
      payload: {'local_id': 's1', 'ended_at': isoUtc(now), 'unclean': false},
      now: now,
    );

    final acks = <SyncAck>[];
    worker.acks.listen(acks.add);
    expect(await worker.syncOnce(), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect((await db.sessionDao.byId('s1'))!.serverId, isNotNull);
    expect(await db.sessionDao.unsyncedHeartbeats(), isEmpty);
    expect(await db.outboxDao.pendingCount(), 0);
    expect(api.acceptedHeartbeats, 2);
    expect(acks.single.projectId, 'p-101');
  });

  test(
    'offline: nothing is lost, and sync resumes without double counting',
    () async {
      await localSession('s1');
      api.offline = true;
      expect(await worker.syncOnce(), isFalse);
      expect(worker.isOnline, isFalse);
      expect(await db.sessionDao.unsyncedHeartbeats(), hasLength(2));
      expect(await db.outboxDao.pendingCount(), 1);

      // Still inside the backoff window.
      api.offline = false;
      expect(await worker.syncOnce(), isFalse);

      now = now.add(const Duration(minutes: 10));
      expect(await worker.syncOnce(), isTrue);
      expect(worker.isOnline, isTrue);
      expect(api.acceptedHeartbeats, 2);

      // A second pass sends nothing new.
      await db.sessionDao.insertHeartbeat(
        HeartbeatsCompanion.insert(
          clientId: 's1-hb-late',
          localSessionId: 's1',
          fromTime: now,
          toTime: now.add(const Duration(minutes: 1)),
          activeSecs: 60,
          idleSecs: 0,
          appsJson: '{}',
        ),
      );
      await worker.syncOnce(ignoreBackoff: true);
      expect(api.acceptedHeartbeats, 3);
      final today = await api.myHoursToday();
      expect(today.activeSecs, 160);
    },
  );

  test('a stop waits until its heartbeats are synced', () async {
    await localSession('s1');
    await db.sessionDao.closeSession('s1', endedAt: now, status: 'closed');
    await db.outboxDao.enqueue(
      clientId: 'stop-s1',
      kind: OutboxKind.sessionStop,
      payload: {'local_id': 's1', 'ended_at': isoUtc(now), 'unclean': false},
      now: now,
    );
    // Session has no server id yet, so the stop cannot go first.
    await db.outboxDao.markDone(
      (await db.outboxDao.due(
        now,
      )).firstWhere((r) => r.kind == 'session_start').id,
    );
    await worker.syncOnce();
    final left = await db.outboxDao.due(now);
    expect(left.map((r) => r.kind), ['session_stop']);
  });

  test('permanent rejections are parked, not retried forever', () async {
    await db.outboxDao.enqueue(
      clientId: 'bad-task',
      kind: OutboxKind.taskComplete,
      payload: {'task_id': 'no-such-task', 'note': ''},
      now: now,
    );
    await worker.syncOnce();
    expect(await db.outboxDao.due(now), isEmpty);
    expect(await db.outboxDao.pendingCount(), 1);
  });

  group('unclean session recovery', () {
    test('closes at the last heartbeat and queues stop + event', () async {
      await localSession('s1');
      final last = now.add(const Duration(minutes: 7));
      await db.sessionDao.setLastHeartbeat('s1', last);

      final closed = await RecoveryService(
        db: db,
        clock: () => now,
      ).recoverUncleanSessions();
      expect(closed, 1);

      final s = (await db.sessionDao.byId('s1'))!;
      expect(s.status, 'unclean');
      expect(s.endedAt, last);

      final rows = await db.outboxDao.due(now.add(const Duration(days: 1)));
      final stop = rows.firstWhere((r) => r.kind == 'session_stop');
      expect(
        (jsonDecode(stop.payloadJson) as Map<String, dynamic>)['unclean'],
        true,
      );
      expect(rows.where((r) => r.kind == 'event'), hasLength(1));
    });

    test('a session with no heartbeat closes at its start', () async {
      await localSession('s1', heartbeats: 0);
      await RecoveryService(db: db, clock: () => now).recoverUncleanSessions();
      expect((await db.sessionDao.byId('s1'))!.endedAt, now);
    });

    test('an unclean day requires a report until one is submitted', () async {
      await localSession('s1');
      await RecoveryService(db: db, clock: () => now).recoverUncleanSessions();
      expect(await db.reportDao.pendingDate('2026-10-05'), '2026-10-05');

      await db.reportDao.save(
        date: '2026-10-05',
        workerId: 'w-1',
        json: '{}',
        submitted: true,
      );
      expect(await db.reportDao.pendingDate('2026-10-05'), isNull);
    });

    test('a clean earlier day without a report is also pending', () async {
      await localSession('s1');
      await db.sessionDao.closeSession('s1', endedAt: now, status: 'closed');
      expect(await db.reportDao.pendingDate('2026-10-05'), isNull);
      expect(await db.reportDao.pendingDate('2026-10-06'), '2026-10-05');
    });

    test('nothing to recover is a no-op', () async {
      expect(
        await RecoveryService(
          db: db,
          clock: () => now,
        ).recoverUncleanSessions(),
        0,
      );
    });
  });

  test('harness project helper compiles', () {
    expect(project().code, 'KP-1');
    expect(const Value(1).present, isTrue);
  });
}
