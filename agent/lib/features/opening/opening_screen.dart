import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../common/lock_scaffold.dart';
import '../project_select/project_select_controller.dart';
import 'opening_controller.dart';

class OpeningScreen extends ConsumerStatefulWidget {
  const OpeningScreen({super.key});

  @override
  ConsumerState<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends ConsumerState<OpeningScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(openingControllerProvider.notifier).run();
      final s = ref.read(openingControllerProvider);
      // Go straight to the timer unless there is something to read.
      if (s.phase == OpeningPhase.done && !s.hasWarnings && mounted) {
        await ref.read(flowCoordinatorProvider).showBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(openingControllerProvider);
    final selection = ref.watch(startSelectionProvider);
    final theme = Theme.of(context);
    final result = s.result;

    return LockScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selection == null
                        ? 'Opening project'
                        : 'Opening ${selection.project.code}',
                    style: theme.textTheme.headlineMedium,
                  ),
                  if (selection != null)
                    Text(
                      '${selection.project.name} · ${selection.task.title}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: AppColors.muted),
                    ),
                  const SizedBox(height: 24),
                  if (s.phase == OpeningPhase.failed)
                    Text(
                      s.error ?? 'Could not open the project.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: AppColors.danger),
                    )
                  else ...[
                    LinearProgressIndicator(
                      value: s.phase == OpeningPhase.done
                          ? 1
                          : (s.total == 0 ? null : s.done / s.total),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.phase == OpeningPhase.syncing
                          ? 'Getting latest files… ${s.current}'
                          : s.phase == OpeningPhase.done
                              ? 'Ready'
                              : 'Starting timer…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (result != null && result.offline)
                    _Note(
                      Icons.cloud_off,
                      'Offline: opened your local files. Newer versions will '
                      'download next time.',
                    ),
                  for (final e in (result?.readOnly.entries ??
                      const <MapEntry<String, String>>[]))
                    _Note(
                      Icons.lock_outline,
                      '${e.key}: in use by ${e.value}. Read-only for you.',
                    ),
                  for (final f in (result?.failed ?? const <String>[]))
                    _Note(Icons.error_outline, 'Could not download $f'),
                  const SizedBox(height: 24),
                  if (s.phase == OpeningPhase.done)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: ref.read(flowCoordinatorProvider).showBar,
                        child: const Text('Start working'),
                      ),
                    ),
                  if (s.phase == OpeningPhase.failed)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: ref.read(flowCoordinatorProvider).openPrompt,
                        child: const Text('Back'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
