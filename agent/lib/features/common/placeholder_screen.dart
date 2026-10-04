import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../project_select/project_select_controller.dart';
import 'lock_scaffold.dart';

/// Stand-in for screens built in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Phase 1 end of the flow: confirms the selection. Phase 2–3 replace this
/// with session start, folder sync and unlocking to the Timer Bar.
class OpeningPlaceholderScreen extends ConsumerWidget {
  const OpeningPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(startSelectionProvider);
    return PlaceholderScreen(
      title: selection == null
          ? 'Nothing selected'
          : 'Starting ${selection.project.code}',
      message: selection == null
          ? ''
          : '${selection.project.name}\n${selection.task.title}\n\n'
              'Session tracking and folder sync arrive in phases 2–3.',
      action: OutlinedButton.icon(
        onPressed: () => context.go(Routes.projects),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to projects'),
      ),
    );
  }
}
