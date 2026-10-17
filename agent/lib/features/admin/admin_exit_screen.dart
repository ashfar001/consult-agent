import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/admin_gate.dart';
import '../common/lock_scaffold.dart';

/// Super-admin password prompt to close the agent in an emergency.
class AdminExitScreen extends ConsumerStatefulWidget {
  const AdminExitScreen({super.key});

  @override
  ConsumerState<AdminExitScreen> createState() => _AdminExitScreenState();
}

class _AdminExitScreenState extends ConsumerState<AdminExitScreen> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(flowCoordinatorProvider)
        .tryAdminExit(_password.text);
    if (!mounted) return;
    _password.clear();
    setState(() {
      _busy = false;
      _error = switch (result) {
        AdminResult.ok => null,
        AdminResult.wrong => 'Wrong password',
        AdminResult.locked =>
          'Too many tries. Wait ${ref.read(adminGateProvider).lockedSecs} s',
        AdminResult.notConfigured => 'No admin password is set on this PC',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LockScaffold(
      compact: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Administrator exit', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Closes the agent. A running session is saved first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                autofocus: true,
                obscureText: true,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Admin password'),
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(
                height: 24,
                child: _error == null
                    ? null
                    : Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : ref.read(flowCoordinatorProvider).cancelAdminExit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 44),
                    ),
                    child: const Text('Exit agent'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
