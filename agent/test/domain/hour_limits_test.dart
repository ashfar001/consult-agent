import 'package:consult_agent/data/models/project.dart';
import 'package:consult_agent/domain/hour_limits.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project({
  double allocatedHours = 10,
  int usedSecs = 0,
  OverrunMode mode = OverrunMode.allow,
}) => Project(
  id: 'p',
  code: 'P',
  name: 'P',
  client: 'C',
  overrunMode: mode,
  folderTemplate: const [],
  myAllocatedHours: allocatedHours,
  myUsedSeconds: usedSecs,
  projectTotalHours: 0,
  projectUsedSeconds: 0,
  tasks: const [],
);

void main() {
  group('HourUsage', () {
    test('ratio, remaining and level below warning', () {
      final u = HourUsage.ofProject(_project(usedSecs: 7 * 3600));
      expect(u.allocatedSecs, 36000);
      expect(u.ratio, closeTo(0.7, 1e-9));
      expect(u.remainingSecs, 3 * 3600);
      expect(u.level, UsageLevel.normal);
    });

    test('exactly 80% is warning', () {
      final u = HourUsage.ofProject(_project(usedSecs: 8 * 3600));
      expect(u.level, UsageLevel.warning);
    });

    test('exactly 100% is over; remaining clamps at 0', () {
      final u = HourUsage.ofProject(_project(usedSecs: 10 * 3600));
      expect(u.level, UsageLevel.over);
      expect(u.remainingSecs, 0);
      expect(u.overrunSecs, 0);
      expect(u.progress, 1);
    });

    test('overrun seconds beyond allocation', () {
      final u = HourUsage.ofProject(_project(usedSecs: 11 * 3600));
      expect(u.remainingSecs, 0);
      expect(u.overrunSecs, 3600);
      expect(u.progress, 1);
    });

    test('unsynced local seconds count toward usage', () {
      final u = HourUsage.ofProject(
        _project(usedSecs: 7 * 3600 + 3000),
        unsyncedSecs: 600,
      );
      expect(u.usedSecs, 8 * 3600);
      expect(u.level, UsageLevel.warning);
    });

    test('zero allocation: unused is normal, any use is over', () {
      expect(
        HourUsage.ofProject(_project(allocatedHours: 0)).level,
        UsageLevel.normal,
      );
      final used = HourUsage.ofProject(
        _project(allocatedHours: 0, usedSecs: 1),
      );
      expect(used.level, UsageLevel.over);
      expect(used.progress, 1);
    });
  });

  group('canTrack', () {
    test('allow mode keeps tracking past 100%', () {
      final p = _project(usedSecs: 20 * 3600);
      expect(canTrack(p, HourUsage.ofProject(p)), isTrue);
    });

    test('block mode stops at 100%', () {
      final under = _project(usedSecs: 9 * 3600, mode: OverrunMode.block);
      final at = _project(usedSecs: 10 * 3600, mode: OverrunMode.block);
      expect(canTrack(under, HourUsage.ofProject(under)), isTrue);
      expect(canTrack(at, HourUsage.ofProject(at)), isFalse);
    });
  });

  test('formatHm', () {
    expect(formatHm(0), '0h 00m');
    expect(formatHm(3 * 3600 + 5 * 60 + 59), '3h 05m');
    expect(formatHm(-3600), '-1h 00m');
  });
}
