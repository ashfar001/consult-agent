import 'dart:convert';
import 'dart:io';

import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:consult_agent/services/bar_hide_logic.dart';
import 'package:consult_agent/services/folder_manager.dart';
import 'package:consult_agent/services/sync_worker.dart';
import 'package:consult_agent/services/timer_dock_preferences.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('BarHideLogic', () {
    final t0 = DateTime(2026, 10, 5, 9);
    late BarHideLogic logic;

    setUp(() => logic = BarHideLogic());

    bool sample(int ms, {bool pointer = false, bool focus = false}) =>
        logic.update(
          pointerInside: pointer,
          keyboardFocus: focus,
          now: t0.add(Duration(milliseconds: ms)),
        );

    test('starts collapsed; only a tab hover reveals it', () {
      expect(logic.collapsed, isTrue);
      expect(sample(0), isFalse);
      expect(sample(500, focus: true), isFalse);
      expect(sample(1000, pointer: true), isTrue);
      expect(logic.collapsed, isFalse);
    });

    test('either pointer or keyboard focus keeps the dock open', () {
      expect(sample(0, pointer: true), isTrue);
      expect(sample(5000, pointer: true), isFalse);
      expect(sample(6000, focus: true), isFalse);
      expect(sample(10000, focus: true), isFalse);
      expect(sample(10001), isFalse);
      expect(sample(13000), isFalse);
      expect(sample(13001), isTrue);
      expect(logic.collapsed, isTrue);
    });

    test('regaining either input cancels the pending collapse', () {
      logic.expand();
      expect(sample(0), isFalse);
      expect(sample(2900, pointer: true), isFalse);
      expect(sample(3000), isFalse);
      expect(sample(5900, focus: true), isFalse);
      expect(sample(6000), isFalse);
      expect(sample(8999), isFalse);
      expect(sample(9000), isTrue);
    });

    test('Hide requires the pointer to leave before revealing again', () {
      logic.expand();
      logic.collapseManually();
      expect(sample(0, pointer: true), isFalse);
      expect(sample(1000, pointer: true), isFalse);
      expect(sample(1001), isFalse);
      expect(sample(1002, pointer: true), isTrue);
      expect(logic.collapsed, isFalse);
    });
  });

  test(
    'dock edge survives a fresh preference service and defaults right',
    () async {
      final temp = await Directory.systemTemp.createTemp('timer_dock_test');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/profile/dock-edge');
      expect(await TimerDockPreferences(file).read(), DockEdge.right);
      await TimerDockPreferences(file).write(DockEdge.left);
      expect(await TimerDockPreferences(file).read(), DockEdge.left);
      await TimerDockPreferences(file).write(DockEdge.right);
      expect(await TimerDockPreferences(file).read(), DockEdge.right);
    await TimerDockPreferences(file).write(DockEdge.left);
    expect(await TimerDockPreferences(file).read(), DockEdge.left);
      await file.writeAsString('unknown');
      expect(await TimerDockPreferences(file).read(), DockEdge.right);
    },
  );

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
