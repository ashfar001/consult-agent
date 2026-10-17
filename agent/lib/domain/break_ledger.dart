/// One lunch break piece; [end] is null while it is running.
class BreakPiece {
  const BreakPiece(this.start, [this.end]);

  final DateTime start;
  final DateTime? end;
}

/// The day's lunch break allowance: [allowanceSecs] in at most [maxPieces].
class BreakLedger {
  const BreakLedger({
    required this.allowanceSecs,
    required this.maxPieces,
    this.pieces = const [],
  });

  final int allowanceSecs;
  final int maxPieces;
  final List<BreakPiece> pieces;

  bool get onBreak => pieces.any((p) => p.end == null);

  int get piecesUsed => pieces.length;

  /// Break seconds taken so far, counting a running piece up to [now].
  int takenSecs(DateTime now) {
    var total = 0;
    for (final p in pieces) {
      final secs = (p.end ?? now).difference(p.start).inSeconds;
      total += secs < 0 ? 0 : secs;
    }
    return total;
  }

  int remainingSecs(DateTime now) {
    final r = allowanceSecs - takenSecs(now);
    return r < 0 ? 0 : r;
  }

  /// Seconds beyond the allowance. They are not work time either.
  int overSecs(DateTime now) {
    final o = takenSecs(now) - allowanceSecs;
    return o < 0 ? 0 : o;
  }

  bool canStart(DateTime now) =>
      !onBreak && piecesUsed < maxPieces && remainingSecs(now) > 0;
}
