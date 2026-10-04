import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/api/api_client.dart';
import '../../data/models/models.dart';
import '../../domain/hour_limits.dart';
import '../../services/logging.dart';

class ProjectSelectState {
  const ProjectSelectState({
    this.projects = const [],
    this.loading = false,
    this.offline = false,
    this.fetchedAt,
    this.error,
    this.selectedProjectId,
    this.selectedTaskId,
  });

  final List<Project> projects;
  final bool loading;

  /// Showing the cached list because the server could not be reached.
  final bool offline;
  final DateTime? fetchedAt;
  final String? error;
  final String? selectedProjectId;
  final String? selectedTaskId;

  Project? get selectedProject {
    for (final p in projects) {
      if (p.id == selectedProjectId) return p;
    }
    return null;
  }

  ProjectTask? get selectedTask {
    for (final t in selectedProject?.tasks ?? const <ProjectTask>[]) {
      if (t.id == selectedTaskId) return t;
    }
    return null;
  }

  ProjectSelectState copyWith({
    List<Project>? projects,
    bool? loading,
    bool? offline,
    DateTime? fetchedAt,
    String? Function()? error,
    String? Function()? selectedProjectId,
    String? Function()? selectedTaskId,
  }) =>
      ProjectSelectState(
        projects: projects ?? this.projects,
        loading: loading ?? this.loading,
        offline: offline ?? this.offline,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        error: error != null ? error() : this.error,
        selectedProjectId: selectedProjectId != null
            ? selectedProjectId()
            : this.selectedProjectId,
        selectedTaskId:
            selectedTaskId != null ? selectedTaskId() : this.selectedTaskId,
      );
}

/// Why Start is unavailable.
enum StartBlock {
  noProject('Select a project'),
  hoursExhausted('Hours exhausted. Ask your manager for more hours.'),
  noTask('Select a task');

  const StartBlock(this.message);
  final String message;
}

/// What the worker chose to start.
typedef StartSelection = ({Project project, ProjectTask task});

class ProjectSelectController extends Notifier<ProjectSelectState> {
  @override
  ProjectSelectState build() => const ProjectSelectState();

  /// Fetches assigned projects; on a network failure shows the cached list.
  Future<void> load() async {
    state = state.copyWith(loading: true, error: () => null);
    final api = ref.read(apiClientProvider);
    final cache = ref.read(dbProvider).projectCacheDao;
    final now = ref.read(clockProvider)();
    try {
      final projects = await api.myProjects();
      await cache.replaceAll(projects, now);
      state = _keepSelection(
        state.copyWith(
          projects: projects,
          loading: false,
          offline: false,
          fetchedAt: now,
        ),
      );
    } on ApiException catch (e) {
      log.w('Loading projects failed: $e');
      final cached = await cache.load();
      state = _keepSelection(
        state.copyWith(
          projects: cached.projects,
          loading: false,
          offline: e.isRetryable,
          fetchedAt: cached.fetchedAt,
          error: () => cached.projects.isEmpty
              ? (e.isRetryable
                  ? 'Cannot reach the server and no saved project list is '
                      'available. Check the network and try again.'
                  : e.message)
              : null,
        ),
      );
    }
  }

  ProjectSelectState _keepSelection(ProjectSelectState s) {
    final project = s.selectedProject;
    if (project == null) {
      return s.copyWith(selectedProjectId: () => null, selectedTaskId: () => null);
    }
    if (!project.tasks.any((t) => t.id == s.selectedTaskId)) {
      return s.copyWith(selectedTaskId: () => _defaultTask(project)?.id);
    }
    return s;
  }

  ProjectTask? _defaultTask(Project p) {
    final open = p.openTasks;
    return open.length == 1 ? open.first : null;
  }

  void selectProject(String projectId) {
    final project = state.projects.firstWhere((p) => p.id == projectId);
    state = state.copyWith(
      selectedProjectId: () => projectId,
      selectedTaskId: () => _defaultTask(project)?.id,
    );
  }

  void selectTask(String taskId) {
    state = state.copyWith(selectedTaskId: () => taskId);
  }

  /// Why Start is unavailable, or null if the worker can start.
  StartBlock? startBlock() {
    final project = state.selectedProject;
    if (project == null) return StartBlock.noProject;
    if (!canTrack(project, HourUsage.ofProject(project))) {
      return StartBlock.hoursExhausted;
    }
    if (state.selectedTask == null) return StartBlock.noTask;
    return null;
  }

  StartSelection? selection() {
    if (startBlock() != null) return null;
    return (project: state.selectedProject!, task: state.selectedTask!);
  }
}

final projectSelectControllerProvider =
    NotifierProvider<ProjectSelectController, ProjectSelectState>(
  ProjectSelectController.new,
);

/// Set when Start is pressed; consumed by the opening flow (phase 2–3).
final startSelectionProvider =
    NotifierProvider<StartSelectionNotifier, StartSelection?>(
  StartSelectionNotifier.new,
);

class StartSelectionNotifier extends Notifier<StartSelection?> {
  @override
  StartSelection? build() => null;

  void set(StartSelection? value) => state = value;
}
