import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../domain/hour_limits.dart';
import '../../services/session_manager.dart';
import '../common/lock_scaffold.dart';

/// "Start your lunch break?" so an accidental click can't pause the clock.
class BreakConfirmScreen extends ConsumerStatefulWidget {
  const BreakConfirmScreen({super.key});

  @override
  ConsumerState<BreakConfirmScreen> createState() => _BreakConfirmScreenState();
}

class _BreakConfirmScreenState extends ConsumerState<BreakConfirmScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(sessionManagerProvider.notifier).refreshBreak(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionManagerProvider);
    final flow = ref.read(flowCoordinatorProvider);
    final theme = Theme.of(context);
    final available = s.breakRemainingSecs > 0;
    return LockScaffold(
      compact: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.free_breakfast_outlined,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                available
                    ? 'Start your lunch break?'
                    : 'No break time left today',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                available
                    ? 'Your timer will pause. You have '
                          '${formatHm(s.breakRemainingSecs)} of break left '
                          '(break ${s.breakPieces + 1} of 2).'
                    : 'You have used all of today\'s break.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: flow.showBar,
                    child: Text(available ? 'No, keep working' : 'OK'),
                  ),
                  if (available) ...[
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        final started = await ref
                            .read(sessionManagerProvider.notifier)
                            .startBreak();
                        if (!started) await flow.showBar();
                      },
                      child: const Text('Yes, start break'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
