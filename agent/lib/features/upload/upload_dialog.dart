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
              '${session.project?.code ?? ''} · every file in the project '
              'folder. Changed files are ticked. Each upload becomes a new '
              'version.',
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
                          'No files in this project folder yet. '
                          'Use "Add files" to pick others.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView(
                        children: [
                          for (final g in _groups(s.items))
                            ExpansionTile(
                              key: PageStorageKey('folder-${g.name}'),
                              initiallyExpanded: g.changed > 0,
                              leading: const Icon(Icons.folder_outlined),
                              title: Text(g.name),
                              subtitle: Text(
                                g.changed > 0
                                    ? '${g.items.length} files · '
                                          '${g.changed} changed'
                                    : '${g.items.length} files',
                              ),
                              children: [
                                for (final i in g.items)
                                  _FileTile(
                                    item: i,
                                    busy: s.busy,
                                    onChanged: (v) => c.toggle(i.path, v),
                                  ),
                              ],
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
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: s.busy ? null : c.openFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open folder'),
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

class _Group {
  _Group(this.name) : items = [];

  final String name;
  final List<UploadItem> items;

  int get changed => items.where((i) => i.changed).length;
}

/// Files grouped by top-level project subfolder; folders with changes first.
List<_Group> _groups(List<UploadItem> items) {
  final byName = <String, _Group>{};
  for (final i in items) {
    final parts = i.remotePath.split('/');
    final name = parts.length > 1 ? parts.first : '(project root)';
    byName.putIfAbsent(name, () => _Group(name)).items.add(i);
  }
  final groups = byName.values.toList();
  for (final g in groups) {
    g.items.sort((a, b) {
      if (a.changed != b.changed) return a.changed ? -1 : 1;
      return a.remotePath.compareTo(b.remotePath);
    });
  }
  groups.sort((a, b) {
    if ((a.changed > 0) != (b.changed > 0)) return a.changed > 0 ? -1 : 1;
    return a.name.compareTo(b.name);
  });
  return groups;
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.item,
    required this.busy,
    required this.onChanged,
  });

  final UploadItem item;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final name = item.remotePath.split('/').skip(1).join('/');
    return ListTile(
      dense: true,
      leading: Checkbox(
        value: item.selected,
        onChanged: busy ? null : (v) => onChanged(v ?? false),
      ),
      title: Text(name.isEmpty ? item.remotePath : name),
      subtitle: item.state == 'uploading'
          ? LinearProgressIndicator(value: item.progress)
          : Text(
              '${_size(item.size)}${item.changed ? ' · changed' : ''}',
              style: TextStyle(color: item.changed ? AppColors.warning : null),
            ),
      trailing: switch (item.state) {
        'confirmed' => const Icon(Icons.check_circle, color: AppColors.ok),
        'failed' => const Icon(Icons.error, color: AppColors.danger),
        'queued' => const Text('Queued'),
        _ => null,
      },
    );
  }
}
