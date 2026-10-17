/// One poll of the machine state.
class Sample {
  const Sample({required this.at, required this.idleSecs, required this.app});

  final DateTime at;

  /// Seconds since the last keyboard/mouse input.
  final int idleSecs;

  /// Classified foreground app name.
  final String app;
}

/// Time totals for one heartbeat slice.
class SliceTotals {
  const SliceTotals({
    required this.from,
    required this.to,
    required this.activeSecs,
    required this.idleSecs,
    required this.apps,
  });

  final DateTime from;
  final DateTime to;
  final int activeSecs;
  final int idleSecs;
  final Map<String, int> apps;
}

/// Turns periodic [Sample]s into heartbeat slices.
///
/// Each sample covers the time since the previous one. It is active unless
/// the user has been idle for [idleThresholdSecs], or the gap since the last
/// sample exceeds [maxGapSecs] (sleep, hibernate or a stalled app), in which
/// case the whole gap counts as idle. Gaps are never counted as active.
class ActivityAccumulator {
  ActivityAccumulator({
    required this.idleThresholdSecs,
    required this.sliceSecs,
    this.maxGapSecs = 15,
  });

  final int idleThresholdSecs;
  final int sliceSecs;
  final int maxGapSecs;

  DateTime? _sliceStart;
  DateTime? _last;
  int _activeMs = 0;
  int _idleMs = 0;
  final Map<String, int> _appMs = {};
  bool _lastWasIdle = false;

  bool get isIdle => _lastWasIdle;

  /// Active seconds in the slice that has not been flushed yet.
  int get pendingActiveSecs => (_activeMs / 1000).round();

  /// Starts a fresh slice at [now], dropping any partial one. [clearIdle]
  /// is false when a slice closes mid-session, so the idle status carries on.
  void reset(DateTime now, {bool clearIdle = true}) {
    _sliceStart = now;
    _last = now;
    _activeMs = 0;
    _idleMs = 0;
    _appMs.clear();
    if (clearIdle) _lastWasIdle = false;
  }

  /// Records [s]; returns a finished slice once [sliceSecs] have elapsed.
  SliceTotals? add(Sample s) {
    if (_sliceStart == null) reset(s.at);
    var dt = s.at.difference(_last!).inMilliseconds;
    if (dt < 0) dt = 0;
    final gap = dt > maxGapSecs * 1000;
    if (gap || s.idleSecs >= idleThresholdSecs) {
      _idleMs += dt;
      _lastWasIdle = true;
    } else {
      _activeMs += dt;
      _appMs.update(s.app, (v) => v + dt, ifAbsent: () => dt);
      _lastWasIdle = false;
    }
    _last = s.at;
    if (s.at.difference(_sliceStart!).inSeconds >= sliceSecs) {
      return flush(s.at);
    }
    return null;
  }

  /// Closes the current slice at [now]. Null if nothing was recorded.
  SliceTotals? flush(DateTime now) {
    final start = _sliceStart;
    if (start == null) return null;
    if (_activeMs == 0 && _idleMs == 0) {
      reset(now, clearIdle: false);
      return null;
    }
    final totals = SliceTotals(
      from: start,
      to: now.isBefore(start) ? start : now,
      activeSecs: (_activeMs / 1000).round(),
      idleSecs: (_idleMs / 1000).round(),
      apps: {
        for (final e in _appMs.entries)
          if ((e.value / 1000).round() > 0) e.key: (e.value / 1000).round(),
      },
    );
    reset(now, clearIdle: false);
    return totals;
  }
}
