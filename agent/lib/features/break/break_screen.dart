import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../domain/hour_limits.dart';
import '../../services/session_manager.dart';
import '../common/lock_scaffold.dart';

String _mmss(int secs) {
  final m = secs ~/ 60;
  final s = secs % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class BreakScreen extends ConsumerStatefulWidget {
  const BreakScreen({super.key});

  @override
  ConsumerState<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends ConsumerState<BreakScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(sessionManagerProvider.notifier).refreshBreak();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionManagerProvider);
    final theme = Theme.of(context);
    final usedUp = s.breakRemainingSecs == 0;
    return LockScaffold(
      compact: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('On lunch break', style: theme.textTheme.titleLarge),
            Text(
              'Break ${s.breakPieces} · timer paused',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              usedUp ? 'Break used up' : _mmss(s.breakRemainingSecs),
              style: theme.textTheme.displaySmall?.copyWith(
                color: usedUp ? AppColors.danger : AppColors.primary,
              ),
            ),
            Text(
              usedUp
                  ? 'Time from now is not counted as work'
                  : '${formatHm(s.breakRemainingSecs)} of break left today',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(sessionManagerProvider.notifier).endBreak();
                await ref.read(flowCoordinatorProvider).showBar();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume work'),
            ),
          ],
        ),
      ),
    );
  }
}
