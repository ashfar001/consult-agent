import 'dart:convert';
import 'dart:ui';

import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/services/bar_hide_logic.dart';
import 'package:consult_agent/services/folder_manager.dart';
import 'package:consult_agent/services/sync_worker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('BarHideLogic', () {
    const bar = Rect.fromLTWH(500, 0, 400, 56);
    final t0 = DateTime(2026, 10, 5, 9);
    late BarHideLogic logic;

    setUp(() => logic = BarHideLogic()..reset(t0));

    DateTime at(int secs) => t0.add(Duration(seconds: secs));

    test('stays out while the cursor is on or near the bar', () {
      for (var s = 0; s < 30; s++) {
        expect(
          logic.update(cursor: const Offset(600, 30), bar: bar, now: at(s)),
          isFalse,
        );
      }
      expect(logic.collapsed, isFalse);
      // Just outside the edge still counts as near.
      expect(
        logic.update(cursor: const Offset(495, 30), bar: bar, now: at(31)),
        isFalse,
      );
    });

    test('collapses once the cursor has been away for 3 s', () {
      // The bar just appeared at t0; the cursor never came near it.
      const away = Offset(100, 500);
      expect(logic.update(cursor: away, bar: bar, now: at(1)), isFalse);
      expect(logic.update(cursor: away, bar: bar, now: at(2)), isFalse);
      expect(logic.update(cursor: away, bar: bar, now: at(3)), isTrue);
      expect(logic.collapsed, isTrue);
    });

    test('coming back near the bar resets the timer', () {
      logic.update(cursor: const Offset(100, 500), bar: bar, now: at(1));
      logic.update(cursor: const Offset(600, 20), bar: bar, now: at(2));
      expect(
        logic.update(cursor: const Offset(100, 500), bar: bar, now: at(4)),
        isFalse,
      );
      expect(logic.collapsed, isFalse);
    });

    test('touching the strip expands it; elsewhere does not', () {
      logic.update(cursor: const Offset(100, 500), bar: bar, now: at(5));
      expect(logic.collapsed, isTrue);

      // Top edge but beside the bar, or below the strip: stays collapsed.
      expect(
        logic.update(cursor: const Offset(100, 2), bar: bar, now: at(6)),
        isFalse,
      );
      expect(
        logic.update(cursor: const Offset(600, 30), bar: bar, now: at(6)),
        isFalse,
      );

      expect(
        logic.update(cursor: const Offset(600, 2), bar: bar, now: at(7)),
        isTrue,
      );
      expect(logic.collapsed, isFalse);
    });
  });

  group('subfolderForTask', () {
    const template = [
      '01_Survey',
      '02_Drawings',
      '03_Structural',
      '04_KSMART',
      '05_Exports',
      '06_Client-Docs',
    ];
    String? pick(String t) => subfolderForTask(t, template);

    test('matches the task to its folder', () {
      expect(pick('Structural column layout'), '03_Structural');
      expect(pick('K-SMART permit drawings'), '04_KSMART');
      expect(pick('Ground floor plan'), '02_Drawings');
      expect(pick('Elevations & sections'), '02_Drawings');
      expect(pick('Revit model update'), '02_Drawings');
      expect(pick('Site survey levels'), '01_Survey');
      expect(pick('Export PDF set'), '05_Exports');
      expect(pick('Client agreement'), '06_Client-Docs');
    });

    test('specific topics win over generic drawings', () {
      expect(pick('Structural drawings'), '03_Structural');
      expect(pick('Permit plan'), '04_KSMART');
    });

    test('no match, or folder missing, gives null', () {
      expect(pick('BOQ in Excel'), isNull);
      expect(subfolderForTask('Structural beam', ['02_Drawings']), isNull);
    });
  });

  group('overtime on the wire', () {
    late Harness h;
    setUp(() => h = Harness(DateTime(2026, 10, 5, 9)));
    tearDown(() => h.dispose());

    Future<void> session(String id, String kind) async {
      await h.db.sessionDao.insertSession(
        SessionsCompanion.insert(
          localId: id,
          workerId: 'w-1',
          projectId: 'p-101',
          taskId: 't-1011',
          startedAt: h.now,
          status: 'open',
          kind: Value(kind),
        ),
      );
      await h.db.outboxDao.enqueue(
        clientId: id,
        kind: OutboxKind.sessionStart,
        payload: {
          'client_id': id,
          'project_id': 'p-101',
          'task_id': 't-1011',
          'started_at': isoUtc(h.now),
        },
        now: h.now,
      );
      await h.db.sessionDao.insertHeartbeat(
        HeartbeatsCompanion.insert(
          clientId: '$id-hb',
          localSessionId: id,
          fromTime: h.now,
          toTime: h.now.add(const Duration(minutes: 1)),
          activeSecs: 50,
          idleSecs: 10,
          appsJson: jsonEncode({'AutoCAD': 40, 'Chrome': 10}),
        ),
      );
    }

    test('normal time reaches the server as project time', () async {
      await session('s-normal', 'normal');
      await h.worker.syncOnce(ignoreBackoff: true);
      final today = await h.api.myHoursToday();
      expect(today.activeSecs, 50);
      expect(today.apps, {'AutoCAD': 40, 'Chrome': 10});
      final p = (await h.api.myProjects()).firstWhere((p) => p.id == 'p-101');
      expect(p.myUsedSeconds, 12 * 3600 + 50);
    });

    test('overtime is never added to project or active time', () async {
      await session('s-ot', 'overtime');
      await h.worker.syncOnce(ignoreBackoff: true);
      final today = await h.api.myHoursToday();
      expect(today.activeSecs, 0);
      expect(today.idleSecs, 0);
      // Still visible to the manager, under separate overtime keys.
      expect(today.apps, {
        '${overtimeAppPrefix}AutoCAD': 40,
        '${overtimeAppPrefix}Chrome': 10,
      });
      final p = (await h.api.myProjects()).firstWhere((p) => p.id == 'p-101');
      expect(p.myUsedSeconds, 12 * 3600);
    });
  });
}
