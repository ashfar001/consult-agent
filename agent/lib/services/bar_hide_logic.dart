const timerDockTabWidth = 6.0;
const timerDockWidth = 400.0;
const timerDockHeight = 104.0;
const timerDockHideAfter = Duration(seconds: 3);

/// Tracks the two reasons to keep the dock open. Native hit testing supplies
/// both values, so this policy does not depend on Flutter's window DPI.
class BarHideLogic {
  bool collapsed = true;
  DateTime? _awaySince;
  bool _waitForTabExit = false;

  void reset() {
    collapsed = true;
    _awaySince = null;
    _waitForTabExit = false;
  }

  void expand() {
    collapsed = false;
    _awaySince = null;
    _waitForTabExit = false;
  }

  /// The mouse may still be over the tab after Hide. Require a new hover.
  void collapseManually() {
    collapsed = true;
    _awaySince = null;
    _waitForTabExit = true;
  }

  /// Returns true when the window needs to expand or collapse.
  bool update({
    required bool pointerInside,
    required bool keyboardFocus,
    required DateTime now,
  }) {
    if (collapsed) {
      if (_waitForTabExit) {
        _waitForTabExit = pointerInside;
        return false;
      }
      if (!pointerInside) return false;
      expand();
      return true;
    }

    if (pointerInside || keyboardFocus) {
      _awaySince = null;
      return false;
    }
    _awaySince ??= now;
    if (now.difference(_awaySince!) < timerDockHideAfter) return false;
    collapsed = true;
    return true;
  }
}
