/// The end of normal working hours, from config ("HH:mm", local time).
class WorkdayClock {
  WorkdayClock(String hhmm) : hour = _parse(hhmm).$1, minute = _parse(hhmm).$2;

  final int hour;
  final int minute;

  static (int, int) _parse(String s) {
    final parts = s.split(':');
    final h = int.tryParse(parts.first) ?? 17;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return (h.clamp(0, 23), m.clamp(0, 59));
  }

  DateTime endOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  /// True once [now] has reached the end of normal hours that day.
  bool isOvertime(DateTime now) => !now.isBefore(endOn(now));
}
