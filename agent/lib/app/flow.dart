import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:win32/win32.dart' show VK_F11;

import '../domain/admin_gate.dart';
import '../data/models/models.dart';
import '../services/bar_hide_logic.dart';
import '../services/launch_detector.dart';
import '../services/logging.dart';
import '../services/session_manager.dart';
import '../services/timer_dock_preferences.dart';
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
/// timer dock while working, small windows for breaks / overtime / notices,
/// large dialogs for upload and End Work.
class FlowCoordinator {
  FlowCoordinator(this._ref);

  final Ref _ref;
  FlowScreen _screen = FlowScreen.idle;
  String _route = Routes.idle;
  final _barHide = BarHideLogic();
  Timer? _barTimer;
  bool _barPollPending = false;
  Future<void> _windowTask = Future.value();
  ({FlowScreen screen, String route})? _beforeAdmin;
  DateTime? _dismissedAt;

  GoRouter get _router => _ref.read(routerProvider);
  WindowService get _window => _ref.read(windowServiceProvider);

  FlowScreen get screen => _screen;

  void start() {
    final cfg = _ref.read(configProvider);
    final detector = LaunchDetector(
      lister: _ref.read(processListerProvider),
      triggers: cfg.triggerApps,
      pollInterval: Duration(seconds: cfg.launchPollSecs),
      isDue: _isDue,
    );
    detector.promptRequests.listen((_) => openPrompt());
    _ref.onDispose(detector.dispose);
    detector.start();
    final hotkey = HotkeyWatcher()..start();
    hotkey.pressed.listen((_) => openAdminExit());
    _ref.onDispose(hotkey.dispose);
    final controlsHotkey = HotkeyWatcher(functionKey: VK_F11)..start();
    controlsHotkey.pressed.listen((_) => toggleControls());
    _ref.onDispose(controlsHotkey.dispose);
    // A worker opening ConsultAgent must be able to sign in immediately.
    // The first native window is hidden until the prompt route is selected.
    unawaited(Future.microtask(openPrompt));
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

  Future<void> _queueWindowTask(Future<void> Function() task) {
    final next = _windowTask.then((_) => task());
    _windowTask = next.catchError((Object e, StackTrace st) {
      log.e('Window transition failed', error: e, stackTrace: st);
    });
    return _windowTask;
  }

  Future<void> _show(FlowScreen screen, String route) => _queueWindowTask(
    () async {
      _barTimer?.cancel();
      _barTimer = null;
      _screen = screen;
      _route = route;
      final mode = switch (screen) {
        FlowScreen.idle => WindowMode.hidden,
        FlowScreen.prompt => WindowMode.prompt,
        FlowScreen.bar => WindowMode.bar,
        FlowScreen.small => WindowMode.small,
        FlowScreen.dialog => WindowMode.dialog,
      };
      if (mode == WindowMode.hidden) {
        await _window.setMode(mode);
        _router.go(route);
      } else {
        // Select the destination before exposing the native window. Waiting for
        // endOfFrame here deadlocks on Windows while the window is hidden.
        _router.go(route);
        await _window.setMode(mode);
        if (mode == WindowMode.bar) {
          _barHide.reset();
          _barTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
            if (_barPollPending) return;
            _barPollPending = true;
            unawaited(
              _queueWindowTask(() async {
                if (_barTimer == timer) await _pollBar();
              }).whenComplete(() => _barPollPending = false),
            );
          });
        }
      }
    },
  );

  Future<void> _pollBar() async {
    final input = await _window.dockInput();
    if (input == null || _barTimer == null) return;
    final wasCollapsed = _barHide.collapsed;
    if (_barHide.update(
      pointerInside: input.pointerInside,
      keyboardFocus: input.keyboardFocus,
      now: _ref.read(clockProvider)(),
    )) {
      try {
        await _window.setBarCollapsed(_barHide.collapsed);
      } on Object {
        _barHide.collapsed = wasCollapsed;
        rethrow;
      }
    }
  }

  void dispose() {
    _barTimer?.cancel();
    _barTimer = null;
  }

  /// Ctrl+Shift+F11 opens the project prompt when idle, or toggles the work
  /// controls during a session. This covers CAD already running at startup.
  Future<void> toggleControls() {
    if (_screen == FlowScreen.idle) {
      return openPrompt();
    }
    return _queueWindowTask(() async {
      if (_screen != FlowScreen.bar) return;
      if (_barHide.collapsed) {
        await _window.setBarCollapsed(false, focus: true);
        _barHide.expand();
      } else {
        await _collapseBar();
      }
    });
  }

  Future<void> collapseBar() => _queueWindowTask(_collapseBar);

  Future<void> moveDock(DockEdge edge) => _queueWindowTask(() async {
    if (_screen == FlowScreen.bar) await _window.moveDock(edge);
  });

  Future<void> _collapseBar() async {
    if (_screen != FlowScreen.bar || _barHide.collapsed) return;
    await _window.setBarCollapsed(true);
    _barHide.collapseManually();
    await _pollBar();
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

  /// Asks before starting a lunch break, so a stray click can't pause the clock.
  Future<void> askBreak() => _show(FlowScreen.small, Routes.breakConfirm);

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
  ref.onDispose(flow.dispose);
  ref.listen(sessionManagerProvider, flow.onSession);
  return flow;
});
