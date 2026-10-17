import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../data/models/models.dart';
import '../common/lock_scaffold.dart';
import 'end_day_controller.dart';

String _size(int bytes) {
  if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

/// End Work form. With [pending] it is the report for an earlier day that
/// must be filed before a new session can start.
class EndDayScreen extends ConsumerStatefulWidget {
  const EndDayScreen({super.key, required this.pending});

  final bool pending;

  @override
  ConsumerState<EndDayScreen> createState() => _EndDayScreenState();
}

class _EndDayScreenState extends ConsumerState<EndDayScreen> {
  final _summary = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(endDayControllerProvider.notifier)
          .load(pending: widget.pending),
    );
  }

  @override
  void dispose() {
    _summary.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(endDayControllerProvider);
    final c = ref.read(endDayControllerProvider.notifier);
    final theme = Theme.of(context);

    return LockScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.pending ? 'Report for ${s.date} is due' : 'End work',
              style: theme.textTheme.headlineMedium,
            ),
            if (widget.pending)
              Text(
                'The last working day ended without a report. File it to '
                'continue.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _summary,
                    onChanged: c.setSummary,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'What did you do today? (required)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (s.tasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Your tasks', style: theme.textTheme.titleMedium),
                    for (final t in s.tasks)
                      _TaskTile(task: t, controller: c),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    onChanged: c.setNotes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes for the manager (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (s.files.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Files to back up',
                      style: theme.textTheme.titleMedium,
                    ),
                    for (final f in s.files)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: f.selected,
                        onChanged: f.tooLarge
                            ? null
                            : (v) => c.toggleFile(f.path, v ?? false),
                        title: Text(f.remotePath),
                        subtitle: Text(
                          f.tooLarge
                              ? '${_size(f.size)} · too large to upload'
                              : _size(f.size),
                          style: TextStyle(
                            color: f.tooLarge ? AppColors.danger : null,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!widget.pending)
                  TextButton(
                    onPressed: s.busy
                        ? null
                        : ref.read(flowCoordinatorProvider).closeDialog,
                    child: const Text('Back to work'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: s.busy ? null : () => c.submit(pending: widget.pending),
                  icon: s.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(s.busy ? 'Uploading…' : 'Submit report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.controller});

  final TaskRow task;
  final EndDayController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('${task.projectCode} · ${task.title}'),
          ),
          const SizedBox(width: 12),
          DropdownButton<TaskStatus>(
            value: task.status,
            items: const [
              DropdownMenuItem(
                value: TaskStatus.inProgress,
                child: Text('In progress'),
              ),
              DropdownMenuItem(
                value: TaskStatus.completed,
                child: Text('Completed'),
              ),
              DropdownMenuItem(
                value: TaskStatus.blocked,
                child: Text('Blocked'),
              ),
            ],
            onChanged: (v) => controller.setTask(task.taskId, status: v),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (v) => controller.setTask(task.taskId, note: v),
              decoration: const InputDecoration(
                hintText: 'Note',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
