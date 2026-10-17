import 'package:consult_agent/domain/activity_accumulator.dart';
import 'package:consult_agent/domain/app_classifier.dart';
import 'package:consult_agent/domain/break_ledger.dart';
import 'package:consult_agent/domain/file_rules.dart';
import 'package:consult_agent/domain/workday.dart';
import 'package:consult_agent/services/launch_detector.dart';
import 'package:consult_agent/services/sync_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyApp', () {
    test('known apps', () {
      expect(classifyApp('acad.exe', ''), 'AutoCAD');
      expect(classifyApp('ACAD.EXE', ''), 'AutoCAD');
      expect(classifyApp('Revit.exe', ''), 'Revit');
      expect(classifyApp('SketchUp.exe', ''), 'SketchUp');
      expect(classifyApp('EXCEL.EXE', ''), 'Excel');
    });

    test('K-SMART only in a browser, any case', () {
      expect(classifyApp('chrome.exe', 'Home - k-smart portal'), 'K-SMART');
      expect(classifyApp('msedge.exe', 'K-SMART | Permits'), 'K-SMART');
      expect(classifyApp('chrome.exe', 'YouTube'), 'Other:chrome.exe');
      expect(classifyApp('notepad.exe', 'K-SMART notes'), 'Other:notepad.exe');
    });

    test('unknown process keeps its exe name', () {
      expect(classifyApp('foo.exe', 'x'), 'Other:foo.exe');
      expect(classifyApp('', ''), 'Other');
    });
  });

  group('ActivityAccumulator', () {
    final t0 = DateTime(2026, 10, 5, 9);

    Sample at(int secs, {int idle = 0, String app = 'AutoCAD'}) => Sample(
      at: t0.add(Duration(seconds: secs)),
      idleSecs: idle,
      app: app,
    );

    ActivityAccumulator make() =>
        ActivityAccumulator(idleThresholdSecs: 300, sliceSecs: 60)..reset(t0);

    test('counts active time per app and emits a slice every 60 s', () {
      final acc = make();
      SliceTotals? slice;
      for (var s = 5; s <= 60; s += 5) {
        slice = acc.add(at(s, app: s <= 30 ? 'AutoCAD' : 'Excel'));
      }
      expect(slice, isNotNull);
      expect(slice!.activeSecs, 60);
      expect(slice.idleSecs, 0);
      expect(slice.apps, {'AutoCAD': 30, 'Excel': 30});
      expect(slice.from, t0);
      expect(slice.to, t0.add(const Duration(seconds: 60)));
    });

    test('idle at or over the threshold is not active', () {
      final acc = make();
      SliceTotals? slice;
      for (var s = 5; s <= 60; s += 5) {
        slice = acc.add(at(s, idle: s <= 20 ? 0 : 300 + s));
      }
      expect(slice!.activeSecs, 20);
      expect(slice.idleSecs, 40);
      expect(acc.isIdle, isTrue);
    });

    test('a long gap (sleep) is idle, never active', () {
      final acc = make();
      acc.add(at(5));
      final slice = acc.add(at(3600));
      expect(slice!.activeSecs, 5);
      expect(slice.idleSecs, 3595);
    });

    test('flush closes a partial slice and starts a fresh one', () {
      final acc = make();
      acc.add(at(5));
      acc.add(at(10));
      final partial = acc.flush(t0.add(const Duration(seconds: 10)));
      expect(partial!.activeSecs, 10);
      expect(acc.flush(t0.add(const Duration(seconds: 10))), isNull);
      expect(acc.pendingActiveSecs, 0);
    });
  });

  group('BreakLedger', () {
    final t = DateTime(2026, 10, 5, 12);
    BreakLedger ledger(List<BreakPiece> pieces) =>
        BreakLedger(allowanceSecs: 3600, maxPieces: 2, pieces: pieces);

    test('sums closed pieces and a running one', () {
      final l = ledger([
        BreakPiece(t, t.add(const Duration(minutes: 20))),
        BreakPiece(t.add(const Duration(hours: 1))),
      ]);
      final now = t.add(const Duration(hours: 1, minutes: 15));
      expect(l.takenSecs(now), 35 * 60);
      expect(l.remainingSecs(now), 25 * 60);
      expect(l.onBreak, isTrue);
      expect(l.canStart(now), isFalse);
    });

    test('cannot start a third piece or after the allowance is used', () {
      final two = ledger([
        BreakPiece(t, t.add(const Duration(minutes: 10))),
        BreakPiece(
          t.add(const Duration(hours: 1)),
          t.add(const Duration(hours: 1, minutes: 10)),
        ),
      ]);
      expect(two.canStart(t.add(const Duration(hours: 3))), isFalse);

      final used = ledger([BreakPiece(t, t.add(const Duration(minutes: 70)))]);
      final now = t.add(const Duration(hours: 3));
      expect(used.remainingSecs(now), 0);
      expect(used.overSecs(now), 10 * 60);
      expect(used.canStart(now), isFalse);
    });

    test('one piece of any size can be followed by a second', () {
      final l = ledger([BreakPiece(t, t.add(const Duration(minutes: 30)))]);
      expect(l.canStart(t.add(const Duration(hours: 2))), isTrue);
    });
  });

  group('WorkdayClock', () {
    test('overtime starts exactly at the configured time', () {
      final w = WorkdayClock('17:00');
      expect(w.isOvertime(DateTime(2026, 10, 5, 16, 59, 59)), isFalse);
      expect(w.isOvertime(DateTime(2026, 10, 5, 17)), isTrue);
      expect(w.isOvertime(DateTime(2026, 10, 5, 23, 30)), isTrue);
    });

    test('bad config falls back to sane values', () {
      final w = WorkdayClock('nonsense');
      expect(w.hour, 17);
      expect(WorkdayClock('18:30').minute, 30);
    });
  });

  group('isIgnoredFile', () {
    test('ignores temp and lock files', () {
      for (final f in [
        'plan.dwg.bak',
        'plan.sv\$',
        'plan.dwl',
        'plan.dwl2',
        r'C:\p\~$budget.xlsx',
        'x.TMP',
        '~\$a.docx',
      ]) {
        expect(isIgnoredFile(f), isTrue, reason: f);
      }
    });

    test('keeps real files', () {
      for (final f in ['plan.dwg', 'model.rvt', 'BOQ.xlsx', 'tmp_notes.txt']) {
        expect(isIgnoredFile(f), isFalse, reason: f);
      }
    });
  });

  group('shouldPrompt', () {
    final now = DateTime(2026, 10, 5, 9);
    bool call({
      Set<String> running = const {'acad.exe'},
      bool hasSession = false,
      bool onBreak = false,
      bool busy = false,
      DateTime? dismissed,
    }) => shouldPrompt(
      running: running,
      triggers: const {'acad.exe', 'revit.exe', 'sketchup.exe'},
      hasSession: hasSession,
      onBreak: onBreak,
      flowBusy: busy,
      now: now,
      dismissedAt: dismissed,
      retryAfter: const Duration(minutes: 5),
    );

    test('CAD running with nothing active prompts', () {
      expect(call(), isTrue);
    });

    test('Excel or a browser never prompt', () {
      expect(call(running: {'excel.exe', 'chrome.exe'}), isFalse);
    });

    test('not while tracking, on break, or another window is open', () {
      expect(call(hasSession: true), isFalse);
      expect(call(onBreak: true), isFalse);
      expect(call(busy: true), isFalse);
    });

    test('dismissed prompt returns after the retry interval', () {
      expect(
        call(dismissed: now.subtract(const Duration(minutes: 2))),
        isFalse,
      );
      expect(call(dismissed: now.subtract(const Duration(minutes: 5))), isTrue);
    });
  });

  test('sync backoff grows from 5 s to a 5 min cap', () {
    expect(SyncWorker.backoffSecs(1, 1), 5);
    expect(SyncWorker.backoffSecs(2, 1), 10);
    expect(SyncWorker.backoffSecs(3, 1), 20);
    expect(SyncWorker.backoffSecs(20, 1), 300);
  });
}
