import 'dart:ui';

const timerBarStripHeight = 6.0;

/// Decides when the timer bar tucks away to a thin strip at the top edge
/// and when it slides back out.
///
/// It collapses after the cursor has stayed away from the bar for
/// [hideAfter]; touching the strip (the top few pixels, over the bar's
/// width) brings it back.
class BarHideLogic {
  BarHideLogic({
    this.hideAfter = const Duration(seconds: 3),
    this.stripHeight = timerBarStripHeight,
    this.margin = 8,
  });

  final Duration hideAfter;

  /// Visible height of the collapsed strip, and the hot zone that expands it.
  final double stripHeight;

  /// Slack around the bar so a cursor near its edge doesn't count as away.
  final double margin;

  bool collapsed = false;
  DateTime? _awaySince;
  bool _waitForStripExit = false;

  /// Starts a fresh expanded bar at [now].
  void reset(DateTime now) {
    collapsed = false;
    _awaySince = now;
    _waitForStripExit = false;
  }

  /// A pointer already on the strip must leave before it can reveal the bar.
  void collapseManually() {
    collapsed = true;
    _waitForStripExit = true;
  }

  /// Feeds one cursor reading in the same units as the current bar bounds.
  /// Returns true if [collapsed] changed.
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
    final onStrip = bar.contains(cursor) && cursor.dy < bar.top + stripHeight;
    if (_waitForStripExit) {
      _waitForStripExit = onStrip;
      return false;
    }
    if (onStrip) {
      collapsed = false;
      _awaySince = null;
      return true;
    }
    return false;
  }
}
