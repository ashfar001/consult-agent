import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../services/session_manager.dart';
import '../common/lock_scaffold.dart';

class OvertimeScreen extends ConsumerWidget {
  const OvertimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final end = ref.watch(configProvider).workdayEnd;
    final manager = ref.read(sessionManagerProvider.notifier);
    final flow = ref.read(flowCoordinatorProvider);
    return LockScaffold(
      compact: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('Work day ended at $end', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Continue as overtime? Overtime is recorded separately and does '
              'not use up your project hours.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    manager.declineOvertime();
                    await flow.openEndWork();
                  },
                  child: const Text('End work'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    await manager.continueOvertime();
                    await flow.showBar();
                  },
                  child: const Text('Continue overtime'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
