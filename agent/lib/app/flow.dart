import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/admin_gate.dart';
import '../data/models/models.dart';
import '../services/launch_detector.dart';
import '../services/logging.dart';
import '../services/session_manager.dart';
import '../services/win32/hotkey_watcher.dart';
import '../services/window_service.dart';
import '../features/login/auth_controller.dart';
import 'providers.dart';
import 'router.dart';

enum FlowScreen { idle, prompt, bar, small, dialog }

/// Decides which screen and window size to show, and when.
///
/// The PC is never locked. The window stays hidden until a CAD app starts
/// with no session running (project prompt), then follows the session:
/// timer bar while working, small windows for breaks / overtime / notices,
/// large dialogs for upload and End Work.
class FlowCoordinator {
  FlowCoordinator(this._ref);

  final Ref _ref;
  FlowScreen _screen = FlowScreen.idle;
  String _route = Routes.idle;
  ({FlowScreen screen, String route})? _beforeAdmin;
  DateTime? _dismissedAt;

  GoRouter get _router => _ref.read(routerProvider);
  WindowService get _window => _ref.read(windowServiceProvider);

  FlowScreen get screen => _screen;

  void start() {
    final cfg = _ref.read(configProvider);
    final detector = LaunchDetector(
      lister: _ref.read(processListerProvider),
      pollInterval: Duration(seconds: cfg.launchPollSecs),
      isDue: _isDue,
    );
    detector.promptRequests.listen((_) => openPrompt());
    _ref.onDispose(detector.dispose);
    detector.start();
    final hotkey = HotkeyWatcher()..start();
    hotkey.pressed.listen((_) => openAdminExit());
    _ref.onDispose(hotkey.dispose);
    // Demo builds show the prompt straight away so it can be tried anywhere.
    if (cfg.mockApi) unawaited(Future.microtask(openPrompt));
  }

  bool _isDue(Set<String> running) {
    final s = _ref.read(sessionManagerProvider);
    final cfg = _ref.read(configProvider);
    return shouldPrompt(
      running: running,
      triggers: cfg.triggerApps,
      hasSession: s.hasSession || s.status == TrackStatus.workdayEnded,
      onBreak: s.status == TrackStatus.onBreak,
      flowBusy: _screen != FlowScreen.idle,
      now: _ref.read(clockProvider)(),
      dismissedAt: _dismissedAt,
      retryAfter: Duration(minutes: cfg.promptRetryMins),
    );
  }

  /// Reacts to session changes (break, 5 PM, hours blocked, 80% notice).
  void onSession(SessionState? prev, SessionState next) {
    final wasBreak = prev?.status == TrackStatus.onBreak;
    if (next.status == TrackStatus.onBreak && !wasBreak) {
      unawaited(_show(FlowScreen.small, Routes.breakRoute));
    } else if (wasBreak &&
        next.hasSession &&
        next.status != TrackStatus.onBreak) {
      unawaited(_show(FlowScreen.bar, Routes.bar));
    }
    if (next.status == TrackStatus.workdayEnded &&
        prev?.status != TrackStatus.workdayEnded) {
      unawaited(_show(FlowScreen.small, Routes.overtime));
    }
    if (prev?.hasSession == true &&
        !next.hasSession &&
        next.blockMessage != null) {
      unawaited(openPrompt(message: next.blockMessage));
    }
    if (next.notice != null &&
        prev?.notice == null &&
        next.hasSession &&
        next.status != TrackStatus.onBreak) {
      unawaited(_show(FlowScreen.small, Routes.notice));
    }
  }

  Future<void> _show(FlowScreen screen, String route) async {
    _screen = screen;
    _route = route;
    _router.go(route);
    await _window.setMode(switch (screen) {
      FlowScreen.idle => WindowMode.hidden,
      FlowScreen.prompt => WindowMode.prompt,
      FlowScreen.bar => WindowMode.bar,
      FlowScreen.small => WindowMode.small,
      FlowScreen.dialog => WindowMode.dialog,
    });
  }

  Future<void> openPrompt({String? message}) async {
    log.i('Project prompt opened');
    _ref.read(authControllerProvider.notifier).signOut(message: message);
    await _show(FlowScreen.prompt, Routes.prompt);
  }

  /// "Not now": hide, and ask again after the retry interval.
  Future<void> dismissPrompt() async {
    _dismissedAt = _ref.read(clockProvider)();
    _ref.read(authControllerProvider.notifier).signOut();
    await _show(FlowScreen.idle, Routes.idle);
  }

  Future<void> showBar() => _show(FlowScreen.bar, Routes.bar);

  Future<void> showIdle() => _show(FlowScreen.idle, Routes.idle);

  Future<void> openUpload() => _show(FlowScreen.dialog, Routes.upload);

  Future<void> openEndWork() => _show(FlowScreen.dialog, Routes.endDay);

  Future<void> openSummary() => _show(FlowScreen.dialog, Routes.summary);

  Future<void> showPendingReport() =>
      _show(FlowScreen.dialog, Routes.pendingReport);

  /// Back from a dialog: to the bar while working, else hidden.
  Future<void> closeDialog() {
    final s = _ref.read(sessionManagerProvider);
    return s.hasSession ? showBar() : showIdle();
  }

  /// Super-admin exit: Ctrl+Shift+F12 from anywhere.
  Future<void> openAdminExit() async {
    if (_route == Routes.adminExit) return;
    _beforeAdmin = (screen: _screen, route: _route);
    await _show(FlowScreen.small, Routes.adminExit);
  }

  Future<void> cancelAdminExit() async {
    final prev = _beforeAdmin;
    _beforeAdmin = null;
    await _show(prev?.screen ?? FlowScreen.idle, prev?.route ?? Routes.idle);
  }

  /// Checks the password; on success ends the session cleanly, tells the
  /// server, and quits. Wrong attempts are reported to the manager.
  Future<AdminResult> tryAdminExit(String password) async {
    final gate = _ref.read(adminGateProvider);
    final result = gate.verify(password);
    final manager = _ref.read(sessionManagerProvider.notifier);
    switch (result) {
      case AdminResult.wrong:
        log.w('Wrong admin exit password');
        await manager.recordEvent(AgentEventType.adminExitFailed, {});
      case AdminResult.ok:
        log.w('Admin exit');
        final s = _ref.read(sessionManagerProvider);
        await manager.recordEvent(AgentEventType.adminExit, {
          if (s.project != null) 'project_id': s.project!.id,
          'had_session': s.hasSession,
        });
        if (s.hasSession) await manager.endSession();
        try {
          await _ref
              .read(syncWorkerProvider)
              .syncOnce(ignoreBackoff: true)
              .timeout(const Duration(seconds: 3));
        } on Object {
          // Offline: the queued rows sync next time the agent runs.
        }
        await _window.exitApp();
      case AdminResult.locked:
      case AdminResult.notConfigured:
        break;
    }
    return result;
  }
}

final flowCoordinatorProvider = Provider<FlowCoordinator>((ref) {
  final flow = FlowCoordinator(ref);
  ref.listen(sessionManagerProvider, flow.onSession);
  return flow;
});
