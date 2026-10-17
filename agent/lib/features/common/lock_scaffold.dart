import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

/// Shared chrome for every fullscreen lock-mode screen: company name,
/// PC name and a live clock in the header.
class LockScaffold extends ConsumerWidget {
  const LockScaffold({
    super.key,
    required this.child,
    this.trailing,
    this.compact = false,
  });

  final Widget child;
  final Widget? trailing;

  /// Slim header for the small windows.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final device = ref.watch(deviceInfoProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 32,
              vertical: compact ? 8 : 16,
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  config.companyName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const Spacer(),
                if (trailing != null) ...[trailing!, const SizedBox(width: 24)],
                if (!compact) ...[
                  const Icon(Icons.computer, color: Colors.white70, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    device.pcName,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(width: 24),
                ],
                const _Clock(),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  static final _fmt = DateFormat('EEE d MMM  h:mm a');

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _fmt.format(_now),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      );
}
