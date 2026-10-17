import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/flow.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../../domain/hour_limits.dart';
import '../common/lock_scaffold.dart';
import '../login/auth_controller.dart';
import 'project_select_controller.dart';

class ProjectSelectScreen extends ConsumerStatefulWidget {
  const ProjectSelectScreen({super.key});

  @override
  ConsumerState<ProjectSelectScreen> createState() =>
      _ProjectSelectScreenState();
}

class _ProjectSelectScreenState extends ConsumerState<ProjectSelectScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(projectSelectControllerProvider.notifier).load(),
    );
  }

  void _start() {
    final controller = ref.read(projectSelectControllerProvider.notifier);
    final selection = controller.selection();
    if (selection == null) return;
    ref.read(startSelectionProvider.notifier).set(selection);
    context.go(Routes.opening);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectSelectControllerProvider);
    final controller = ref.read(projectSelectControllerProvider.notifier);
    final worker = ref.watch(authControllerProvider).worker;
    final theme = Theme.of(context);
    final block = controller.startBlock();

    return LockScaffold(
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: ref.read(flowCoordinatorProvider).dismissPrompt,
            child: const Text('Not now'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text('Not ${worker?.name.split(' ').first ?? 'you'}?'),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello ${worker?.name ?? ''}',
                        style: theme.textTheme.headlineMedium,
                      ),
                      Text(
                        'Choose the project and task you are working on.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Refresh',
                  onPressed: state.loading ? null : controller.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.offline) _OfflineBanner(fetchedAt: state.fetchedAt),
            if (state.loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(child: _body(state, controller, theme)),
            const SizedBox(height: 16),
            _StartBar(
              state: state,
              block: block,
              onStart: block == null ? _start : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    ProjectSelectState state,
    ProjectSelectController controller,
    ThemeData theme,
  ) {
    if (state.error != null && state.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.projects.isEmpty && !state.loading) {
      return Center(
        child: Text(
          'No projects are assigned to you. Ask your manager.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 420).floor().clamp(1, 4);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 330,
          ),
          itemCount: state.projects.length,
          itemBuilder: (context, i) {
            final p = state.projects[i];
            return ProjectCard(
              project: p,
              selected: p.id == state.selectedProjectId,
              selectedTaskId: p.id == state.selectedProjectId
                  ? state.selectedTaskId
                  : null,
              onSelect: () => controller.selectProject(p.id),
              onSelectTask: (taskId) {
                if (p.id != state.selectedProjectId) {
                  controller.selectProject(p.id);
                }
                controller.selectTask(taskId);
              },
            );
          },
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.fetchedAt});

  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final when = fetchedAt == null
        ? ''
        : ' (saved ${DateFormat('d MMM h:mm a').format(fetchedAt!)})';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Offline: showing your saved project list$when. '
              'Your time is still recorded and will sync later.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartBar extends StatelessWidget {
  const _StartBar({
    required this.state,
    required this.block,
    required this.onStart,
  });

  final ProjectSelectState state;
  final StartBlock? block;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = state.selectedProject;
    final task = state.selectedTask;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: project == null
                  ? Text(
                      'Select a project to begin',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${project.code} · ${project.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          task?.title ?? 'Select a task',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        if (block == StartBlock.hoursExhausted)
                          Text(
                            block!.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                      ],
                    ),
            ),
            FilledButton.icon(
              key: const Key('startButton'),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.selected,
    required this.selectedTaskId,
    required this.onSelect,
    required this.onSelectTask,
  });

  final Project project;
  final bool selected;
  final String? selectedTaskId;
  final VoidCallback onSelect;
  final ValueChanged<String> onSelectTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usage = HourUsage.ofProject(project);
    final level = usage.level;
    final color = AppColors.forUsage(level);
    final blocked = !canTrack(project, usage);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : const Color(0xFFE2E5EA),
          width: selected ? 2.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (project.overrunMode == OverrunMode.block)
                    Tooltip(
                      message: 'Work stops when your hours run out',
                      child: Icon(
                        Icons.block,
                        size: 20,
                        color: blocked ? AppColors.danger : AppColors.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                project.client,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${formatHm(usage.usedSecs)} / '
                    '${formatHm(usage.allocatedSecs)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    level == UsageLevel.over
                        ? (blocked
                              ? 'No hours left'
                              : 'Overrun ${formatHm(usage.overrunSecs)}')
                        : '${formatHm(usage.remainingSecs)} left',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: level == UsageLevel.normal
                          ? AppColors.muted
                          : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usage.progress,
                  minHeight: 8,
                  color: color,
                  backgroundColor: const Color(0xFFE8EBEF),
                ),
              ),
              const SizedBox(height: 12),
              Text('My tasks', style: theme.textTheme.labelLarge),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final t in project.openTasks)
                      _TaskTile(
                        task: t,
                        selected: selected && t.id == selectedTaskId,
                        onTap: () => onSelectTask(t.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final ProjectTask task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (task.status == TaskStatus.inProgress)
              const Text(
                'In progress',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
