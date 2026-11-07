import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/agent_release.dart';
import '../../services/agent_update.dart';
import '../../services/logging.dart';
import '../../services/session_manager.dart';
import '../login/auth_controller.dart';

final agentUpdateServiceProvider = Provider<AgentUpdateService?>((ref) {
  if (!Platform.isWindows || !kReleaseMode) return null;
  final config = ref.watch(configProvider);
  return AgentUpdateService(
    protectedPaths: [
      config.dataDir,
      config.logDir,
      config.projectsRoot,
      config.fallbackProjectsRoot,
    ],
  );
});

class AgentUpdateState {
  const AgentUpdateState({
    this.release,
    this.error,
    this.checking = false,
    this.installing = false,
    this.restarting = false,
    this.progress,
  });

  final AgentRelease? release;
  final String? error;
  final bool checking;
  final bool installing;
  final bool restarting;

  /// Null during the helper's preparation, after downloading.
  final double? progress;
}

class AgentUpdateController extends Notifier<AgentUpdateState?> {
  @override
  AgentUpdateState? build() {
    final service = ref.watch(agentUpdateServiceProvider);
    if (service == null) return null;
    // Startup opens sign-in. The provider stays alive while subsequent
    // prompts are hidden or rebuilt, so this check runs once per app launch.
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(check(afterStartup: true));
    });
    return const AgentUpdateState(checking: true);
  }

  Future<void> check({bool afterStartup = false}) async {
    final service = ref.read(agentUpdateServiceProvider);
    if (service == null || state?.installing == true) return;

    String? previousFailure;
    if (afterStartup) {
      service.acknowledgeStartup();
      previousFailure = service.takePreviousFailure();
    }
    state = const AgentUpdateState(checking: true);
    try {
      final release = await service.check();
      if (ref.mounted) {
        state = AgentUpdateState(release: release, error: previousFailure);
      }
    } on Object catch (error, stack) {
      log.w('Update check failed', error: error, stackTrace: stack);
      if (ref.mounted) {
        state = AgentUpdateState(
          error:
              previousFailure ??
              _message(error, 'Could not check for updates.'),
        );
      }
    }
  }

  bool get _canInstall {
    final auth = ref.read(authControllerProvider);
    final session = ref.read(sessionManagerProvider);
    return !auth.busy &&
        !auth.isSignedIn &&
        !session.hasSession &&
        session.status != TrackStatus.workdayEnded;
  }

  Future<void> install() async {
    final service = ref.read(agentUpdateServiceProvider);
    final current = state;
    final release = current?.release;
    if (service == null ||
        release == null ||
        current!.installing ||
        !_canInstall) {
      return;
    }

    const sessionChanged = UpdateException(
      'Finish your work session and return to sign-in before updating.',
    );
    PreparedAgentUpdate? pending;
    state = AgentUpdateState(release: release, installing: true, progress: 0);
    try {
      pending = await service.prepare(release, (progress) {
        if (ref.mounted) {
          state = AgentUpdateState(
            release: release,
            installing: true,
            progress: progress,
          );
        }
      });
      if (!ref.mounted || !_canInstall) throw sessionChanged;
      state = AgentUpdateState(
        release: release,
        installing: true,
        restarting: true,
      );
      final window = ref.read(windowServiceProvider);
      pending.commit();
      await window.exitApp();
    } on Object catch (error, stack) {
      try {
        pending?.cancel();
      } on FileSystemException catch (cancelError) {
        log.w('Could not cancel update preparation', error: cancelError);
      }
      log.w('Update failed', error: error, stackTrace: stack);
      if (ref.mounted) {
        state = AgentUpdateState(
          release: release,
          error: _message(
            error,
            'Could not install the update. Use the releases page to update manually.',
          ),
        );
      }
    }
  }

  void openReleasesPage() {
    try {
      ref.read(agentUpdateServiceProvider)?.openReleasesPage();
    } on UpdateException catch (error) {
      final current = state;
      state = AgentUpdateState(
        release: current?.release,
        error: [error.message, agentReleasesPage].join(' '),
      );
    }
  }

  String _message(Object error, String fallback) =>
      error is UpdateException ? error.message : fallback;
}

final agentUpdateProvider =
    NotifierProvider<AgentUpdateController, AgentUpdateState?>(
      AgentUpdateController.new,
    );
