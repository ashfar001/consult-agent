import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/folder_manager.dart';
import '../../services/logging.dart';
import '../../services/session_manager.dart';
import '../login/auth_controller.dart';
import '../project_select/project_select_controller.dart';

enum OpeningPhase { starting, syncing, done, failed }

class OpeningState {
  const OpeningState({
    this.phase = OpeningPhase.starting,
    this.done = 0,
    this.total = 0,
    this.current = '',
    this.result,
    this.error,
  });

  final OpeningPhase phase;
  final int done;
  final int total;
  final String current;
  final FolderSyncResult? result;
  final String? error;

  /// Files held by someone else, or downloads that failed.
  bool get hasWarnings =>
      (result?.readOnly.isNotEmpty ?? false) ||
      (result?.failed.isNotEmpty ?? false) ||
      (result?.offline ?? false);
}

/// Starts the session, brings the project folder up to date and opens it.
class OpeningController extends Notifier<OpeningState> {
  @override
  OpeningState build() => const OpeningState();

  Future<void> run() async {
    final selection = ref.read(startSelectionProvider);
    final worker = ref.read(authControllerProvider).worker;
    if (selection == null || worker == null) {
      state = const OpeningState(
        phase: OpeningPhase.failed,
        error: 'Nothing selected. Go back and choose a project.',
      );
      return;
    }
    try {
      await ref.read(sessionManagerProvider.notifier).start(
            workerId: worker.id,
            project: selection.project,
            task: selection.task,
          );
      state = const OpeningState(phase: OpeningPhase.syncing);
      final folders = ref.read(folderManagerProvider);
      final result = await folders.sync(
        selection.project,
        onProgress: (done, total, path) {
          state = OpeningState(
            phase: OpeningPhase.syncing,
            done: done,
            total: total,
            current: path,
          );
        },
      );
      await ref
          .read(fileWatcherProvider)
          .start(selection.project.id, result.folder);
      await folders.open(selection.project, result.folder);
      state = OpeningState(
        phase: OpeningPhase.done,
        done: state.total,
        total: state.total,
        result: result,
      );
      // Anything left over from earlier (offline) uploads.
      unawaited(ref.read(uploaderProvider).processQueue());
    } on Object catch (e, st) {
      log.e('Opening project failed', error: e, stackTrace: st);
      state = OpeningState(phase: OpeningPhase.failed, error: '$e');
    }
  }
}

final openingControllerProvider =
    NotifierProvider<OpeningController, OpeningState>(OpeningController.new);
