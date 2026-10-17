import 'dart:ui';

/// Decides when the timer bar tucks away to a thin strip at the top edge
/// and when it slides back out.
///
/// It collapses after the cursor has stayed away from the bar for
/// [hideAfter]; touching the strip (the top few pixels, over the bar's
/// width) brings it back.
class BarHideLogic {
  BarHideLogic({
    this.hideAfter = const Duration(seconds: 3),
    this.stripHeight = 6,
    this.margin = 8,
  });

  final Duration hideAfter;

  /// Visible height of the collapsed strip, and the hot zone that expands it.
  final double stripHeight;

  /// Slack around the bar so a cursor near its edge doesn't count as away.
  final double margin;

  bool collapsed = false;
  DateTime? _awaySince;

  /// Starts a fresh expanded bar at [now].
  void reset(DateTime now) {
    collapsed = false;
    _awaySince = now;
  }

  /// Feeds one cursor reading ([cursor] and [bar] in the same units, bar as
  /// it looks when expanded). Returns true if [collapsed] changed.
  bool update({
    required Offset cursor,
    required Rect bar,
    required DateTime now,
  }) {
    if (!collapsed) {
      if (bar.inflate(margin).contains(cursor)) {
        _awaySince = null;
        return false;
      }
      _awaySince ??= now;
      if (now.difference(_awaySince!) >= hideAfter) {
        collapsed = true;
        return true;
      }
      return false;
    }
    final onStrip =
        cursor.dy <= stripHeight &&
        cursor.dx >= bar.left &&
        cursor.dx <= bar.right;
    if (onStrip) {
      collapsed = false;
      _awaySince = null;
      return true;
    }
    return false;
  }
}
