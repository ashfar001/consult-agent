import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/theme.dart';
import '../../domain/hour_limits.dart';
import '../common/lock_scaffold.dart';
import '../login/auth_controller.dart';
import 'summary_controller.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(summaryControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(summaryControllerProvider);
    final theme = Theme.of(context);
    return LockScaffold(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Day summary · ${s.date}', style: theme.textTheme.headlineMedium),
            if (s.loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Row(
              children: [
                _Tile('Active', formatHm(s.activeSecs), AppColors.primary),
                _Tile('Idle', formatHm(s.idleSecs), AppColors.muted),
                _Tile('Lunch break', formatHm(s.breakSecs), AppColors.muted),
                _Tile('Overtime', formatHm(s.overtimeSecs), AppColors.warning),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Section(
                      'Hours per app',
                      [
                        for (final a in s.apps)
                          _Line(a.key.replaceFirst('Other:', ''), formatHm(a.value)),
                        if (s.apps.isEmpty && !s.loading)
                          const _Line('No activity recorded', ''),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Section(
                      'Projects',
                      [
                        for (final p in s.projects)
                          _ProjectLine(p),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  ref.read(authControllerProvider.notifier).signOut();
                  ref.read(summaryDateProvider.notifier).set(null);
                  await ref.read(flowCoordinatorProvider).showIdle();
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(child: ListView(children: children)),
            ],
          ),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.left, this.right);

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(left)),
            Text(right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ProjectLine extends StatelessWidget {
  const _ProjectLine(this.p);

  final ProjectSummary p;

  @override
  Widget build(BuildContext context) {
    final level = p.usage.level;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${p.code} · ${p.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Today ${formatHm(p.todayActiveSecs)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: p.usage.progress,
            color: AppColors.forUsage(level),
            backgroundColor: const Color(0xFFE8EBEF),
          ),
          Text(
            level == UsageLevel.over
                ? 'Overrun ${formatHm(p.usage.overrunSecs)}'
                : '${formatHm(p.usage.remainingSecs)} left of '
                    '${formatHm(p.usage.allocatedSecs)}'
                    '${p.estimate ? ' (estimate, offline)' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.forUsage(level) == AppColors.primary
                  ? AppColors.muted
                  : AppColors.forUsage(level),
            ),
          ),
        ],
      ),
    );
  }
}
