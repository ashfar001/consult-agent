import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../services/session_manager.dart';
import '../common/lock_scaffold.dart';
import 'upload_controller.dart';

String _size(int bytes) {
  if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

class UploadDialog extends ConsumerStatefulWidget {
  const UploadDialog({super.key});

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(uploadControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(uploadControllerProvider);
    final c = ref.read(uploadControllerProvider.notifier);
    final session = ref.watch(sessionManagerProvider);
    final theme = Theme.of(context);

    return LockScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Upload files', style: theme.textTheme.headlineMedium),
            Text(
              '${session.project?.code ?? ''} · files you changed in this '
              'project. Each upload becomes a new version.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: s.items.isEmpty
                    ? Center(
                        child: Text(
                          'No changed files yet. Use "Add files" to pick others.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView(
                        children: [
                          for (final i in s.items)
                            ListTile(
                              leading: Checkbox(
                                value: i.selected,
                                onChanged: s.busy
                                    ? null
                                    : (v) => c.toggle(i.path, v ?? false),
                              ),
                              title: Text(i.remotePath),
                              subtitle: i.state == 'uploading'
                                  ? LinearProgressIndicator(value: i.progress)
                                  : Text(_size(i.size)),
                              trailing: switch (i.state) {
                                'confirmed' => const Icon(
                                  Icons.check_circle,
                                  color: AppColors.ok,
                                ),
                                'failed' => const Icon(
                                  Icons.error,
                                  color: AppColors.danger,
                                ),
                                'queued' => const Text('Queued'),
                                _ => null,
                              },
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              onChanged: c.setNote,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: s.completeTask,
              onChanged: (v) => c.setCompleteTask(v ?? false),
              title: Text('Mark "${session.task?.title ?? 'task'}" complete'),
            ),
            if (s.message != null && s.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.message!, style: theme.textTheme.bodyMedium),
              ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: s.busy ? null : c.addFiles,
                  icon: const Icon(Icons.add),
                  label: const Text('Add files'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: s.busy
                      ? null
                      : ref.read(flowCoordinatorProvider).closeDialog,
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: s.busy ? null : c.upload,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
