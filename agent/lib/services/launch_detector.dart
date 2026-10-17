import 'dart:async';

import 'win32/process_lister.dart';

/// Decides whether to raise the project prompt.
///
/// It appears when a CAD app is running, nothing is being tracked, the
/// worker is not on break, and any earlier dismissal is older than
/// [retryAfter].
bool shouldPrompt({
  required Set<String> running,
  required Set<String> triggers,
  required bool hasSession,
  required bool onBreak,
  required bool flowBusy,
  required DateTime now,
  required DateTime? dismissedAt,
  required Duration retryAfter,
}) {
  if (hasSession || onBreak || flowBusy) return false;
  if (!running.any(triggers.contains)) return false;
  return dismissedAt == null || now.difference(dismissedAt) >= retryAfter;
}

/// Polls for running CAD apps and reports when the prompt is due.
class LaunchDetector {
  LaunchDetector({
    required this.lister,
    required this.pollInterval,
    required this.isDue,
  });

  final ProcessLister lister;
  final Duration pollInterval;

  /// Called with the running process names; returns true if the prompt
  /// should be shown now.
  final bool Function(Set<String> running) isDue;

  final _controller = StreamController<void>.broadcast();
  Timer? _timer;
  bool _polling = false;

  Stream<void> get promptRequests => _controller.stream;

  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => pollOnce());
    pollOnce();
  }

  Future<void> pollOnce() async {
    if (_polling) return;
    _polling = true;
    try {
      if (isDue(await lister.running())) _controller.add(null);
    } finally {
      _polling = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }
}
