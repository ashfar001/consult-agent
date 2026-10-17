import 'dart:convert';

import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/domain/hour_limits.dart';
import 'package:consult_agent/services/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  late Harness h;

  // A Monday morning, well before the 17:00 cut-off.
  Harness make([DateTime? at]) => Harness(at ?? DateTime(2026, 10, 5, 9));

  setUp(() => h = make());
  tearDown(() => h.dispose());

  Future<void> begin(Project p) =>
      h.manager.start(workerId: 'w-1', project: p, task: task);

  test('start writes the session and queues the server start', () async {
    await begin(project());
    expect(h.state.status, TrackStatus.active);
    final row = await h.db.sessionDao.openSession();
    expect(row, isNotNull);
    expect(row!.kind, 'normal');
    expect(await h.db.outboxDao.pendingCount(), 1);
  });

  test('a minute of ticks writes one heartbeat with active time and app',
      () async {
    await begin(project());
    await h.run(60);
    final rows = await h.db.sessionDao.unsyncedHeartbeats();
    expect(rows, hasLength(1));
    expect(rows.single.activeSecs, 60);
    expect(rows.single.idleSecs, 0);
    expect(jsonDecode(rows.single.appsJson), {'AutoCAD': 60});
    expect(h.state.todayActiveSecs, 60);
    expect(h.state.unsyncedSecs, 60);
  });

  test('idle time is counted separately and marks the status idle', () async {
    await begin(project());
    h.idle.value = 600;
    await h.run(60);
    final hb = (await h.db.sessionDao.unsyncedHeartbeats()).single;
    expect(hb.activeSecs, 0);
    expect(hb.idleSecs, 60);
    expect(h.state.status, TrackStatus.idle);

    h.idle.value = 0;
    await h.run(5);
    expect(h.state.status, TrackStatus.active);
  });

  test('80% raises a warning notice once', () async {
    // 7h55m used of 10h: five more minutes reaches exactly 80%.
    await begin(project(usedSecs: 7 * 3600 + 55 * 60));
    await h.run(300);
    expect(h.state.usage!.level, UsageLevel.warning);
    expect(h.state.notice, contains('80%'));

    h.manager.clearNotice();
    await h.run(60);
    expect(h.state.notice, isNull);
  });

  test('block mode ends the session at 100%', () async {
    await begin(project(
      usedSecs: 9 * 3600 + 55 * 60,
      mode: OverrunMode.block,
    ));
    await h.run(300);
    expect(h.state.hasSession, isFalse);
    expect(h.state.blockMessage, contains('manager'));
    expect(await h.db.sessionDao.openSession(), isNull);
  });

  test('allow mode keeps tracking and flags overrun', () async {
    await begin(project(usedSecs: 9 * 3600 + 55 * 60));
    await h.run(360);
    expect(h.state.hasSession, isTrue);
    expect(h.state.overrun, isTrue);
    expect(h.state.usage!.level, UsageLevel.over);
  });

  test('server acknowledgement replaces unsynced local seconds', () async {
    // p-101 exists in the mock server (12 h used already).
    await begin(project(id: 'p-101', usedSecs: 3600));
    await h.run(120);
    expect(h.state.unsyncedSecs, 120);
    await h.worker.syncOnce(ignoreBackoff: true);
    await Future<void>.delayed(Duration.zero);
    expect(h.state.unsyncedSecs, 0);
    expect(h.state.serverUsedSecs, 12 * 3600 + 120);
  });

  group('lunch break', () {
    test('time on break is not counted and the break is recorded', () async {
      await begin(project());
      await h.run(60);
      expect(await h.manager.startBreak(), isTrue);
      expect(h.state.status, TrackStatus.onBreak);

      await h.run(30 * 60);
      await h.manager.endBreak();
      expect(h.state.status, TrackStatus.active);
      expect(h.state.breakTakenSecs, 30 * 60);
      expect(h.state.breakRemainingSecs, 30 * 60);

      await h.run(60);
      final beats = await h.db.sessionDao.unsyncedHeartbeats();
      final active = beats.fold<int>(0, (a, b) => a + b.activeSecs);
      expect(active, 120);
    });

    test('at most two pieces, and never more than the allowance', () async {
      await begin(project());
      expect(await h.manager.startBreak(), isTrue);
      await h.run(40 * 60);
      await h.manager.endBreak();

      expect(await h.manager.startBreak(), isTrue);
      await h.run(30 * 60);
      await h.manager.endBreak();
      expect(h.state.breakRemainingSecs, 0);
      expect(h.state.breakPieces, 2);

      expect(await h.manager.startBreak(), isFalse);
    });

    test('break events are queued for the manager', () async {
      await begin(project());
      await h.manager.startBreak();
      await h.run(60);
      await h.manager.endBreak();
      final rows = await h.db.outboxDao.due(h.now.add(const Duration(days: 1)));
      final types = [
        for (final r in rows.where((r) => r.kind == 'event'))
          (jsonDecode(r.payloadJson) as Map<String, dynamic>)['type'],
      ];
      expect(types, ['break_start', 'break_end']);
    });
  });

  group('work day end', () {
    test('a normal session stops at 17:00 and offers overtime', () async {
      h.now = DateTime(2026, 10, 5, 16, 59);
      await begin(project());
      await h.run(120);
      expect(h.state.status, TrackStatus.workdayEnded);
      expect(h.state.hasSession, isFalse);
      expect(await h.db.sessionDao.openSession(), isNull);

      final rows = await h.db.outboxDao.due(h.now.add(const Duration(days: 1)));
      final kinds = rows.map((r) => r.kind).toList();
      expect(kinds, containsAll(['session_stop', 'event']));
    });

    test('continuing starts an overtime session', () async {
      h.now = DateTime(2026, 10, 5, 16, 59);
      await begin(project());
      await h.run(120);
      await h.manager.continueOvertime();
      expect(h.state.overtime, isTrue);
      expect(h.state.hasSession, isTrue);
      final s = await h.db.sessionDao.openSession();
      expect(s!.kind, 'overtime');
    });

    test('overtime does not use up the allocation or block', () async {
      h.now = DateTime(2026, 10, 5, 17, 30);
      await begin(project(
        usedSecs: 9 * 3600 + 59 * 60,
        mode: OverrunMode.block,
      ));
      expect(h.state.overtime, isTrue);
      await h.run(600);
      expect(h.state.hasSession, isTrue);
      expect(h.state.blockMessage, isNull);
      expect(h.state.usage!.unsyncedSecs, 0);
      expect(h.state.todayActiveSecs, 600);
      expect(await h.db.sessionDao.unsyncedActiveSecs('p-1'), 0);
    });

    test('declining overtime clears the session for End Work', () async {
      h.now = DateTime(2026, 10, 5, 16, 59);
      await begin(project());
      await h.run(120);
      h.manager.declineOvertime();
      expect(h.state.status, TrackStatus.none);
    });
  });

  test('endSession flushes time and queues the stop', () async {
    await begin(project());
    await h.run(30);
    await h.manager.endSession();
    expect(h.state.hasSession, isFalse);
    final beats = await h.db.sessionDao.unsyncedHeartbeats();
    expect(beats.fold<int>(0, (a, b) => a + b.activeSecs), 30);
    final rows = await h.db.outboxDao.due(h.now.add(const Duration(days: 1)));
    expect(rows.map((r) => r.kind), contains('session_stop'));
  });
}
