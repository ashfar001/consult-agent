import '../data/models/project.dart';

/// Allocation usage band for colouring and limit enforcement.
enum UsageLevel { normal, warning, over }

const double warningRatio = 0.8;

/// A worker's hour usage on one project.
///
/// [serverUsedSecs] is the server's source-of-truth figure; [unsyncedSecs] is
/// active time recorded locally but not yet acknowledged by the server.
class HourUsage {
  const HourUsage({
    required this.allocatedSecs,
    required this.serverUsedSecs,
    this.unsyncedSecs = 0,
  });

  factory HourUsage.ofProject(Project p, {int unsyncedSecs = 0}) => HourUsage(
        allocatedSecs: (p.myAllocatedHours * 3600).round(),
        serverUsedSecs: p.myUsedSeconds,
        unsyncedSecs: unsyncedSecs,
      );

  final int allocatedSecs;
  final int serverUsedSecs;
  final int unsyncedSecs;

  int get usedSecs => serverUsedSecs + unsyncedSecs;

  int get remainingSecs {
    final r = allocatedSecs - usedSecs;
    return r < 0 ? 0 : r;
  }

  int get overrunSecs {
    final o = usedSecs - allocatedSecs;
    return o < 0 ? 0 : o;
  }

  /// used / allocated. With no allocation, any use counts as fully over.
  double get ratio {
    if (allocatedSecs <= 0) return usedSecs > 0 ? double.infinity : 0;
    return usedSecs / allocatedSecs;
  }

  UsageLevel get level {
    final r = ratio;
    if (r >= 1) return UsageLevel.over;
    if (r >= warningRatio) return UsageLevel.warning;
    return UsageLevel.normal;
  }

  /// Progress bar value clamped to 0..1.
  double get progress => ratio.isFinite ? ratio.clamp(0, 1).toDouble() : 1;
}

/// Whether a worker may start (or keep) tracking on [project].
bool canTrack(Project project, HourUsage usage) =>
    project.overrunMode == OverrunMode.allow ||
    usage.level != UsageLevel.over;

/// "12h 05m" style formatting for hours displays.
String formatHm(int secs) {
  final neg = secs < 0;
  final s = secs.abs();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return '${neg ? '-' : ''}${h}h ${m.toString().padLeft(2, '0')}m';
}
