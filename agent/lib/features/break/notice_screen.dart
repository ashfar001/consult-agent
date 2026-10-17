import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../services/session_manager.dart';
import '../common/lock_scaffold.dart';

/// One-off message from the session (e.g. the 80% hours warning).
class NoticeScreen extends ConsumerWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(sessionManagerProvider.select((s) => s.notice));
    final theme = Theme.of(context);
    return LockScaffold(
      compact: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 40, color: AppColors.warning),
            const SizedBox(height: 8),
            Text(
              message ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                ref.read(sessionManagerProvider.notifier).clearNotice();
                await ref.read(flowCoordinatorProvider).showBar();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
