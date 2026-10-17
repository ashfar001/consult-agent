import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flow.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../common/lock_scaffold.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController();
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();

  @override
  void dispose() {
    _employeeId.dispose();
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _submit() {
    ref
        .read(authControllerProvider.notifier)
        .login(_employeeId.text, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(configProvider);
    final theme = Theme.of(context);

    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null && prev?.busy == true) {
        _pin.clear();
        _pinFocus.requestFocus();
      }
    });

    return LockScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to start work',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This PC is locked until you sign in and choose a project.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      key: const Key('employeeId'),
                      controller: _employeeId,
                      autofocus: true,
                      enabled: !auth.busy,
                      textCapitalization: TextCapitalization.characters,
                      style: theme.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _pinFocus.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('pin'),
                      controller: _pin,
                      focusNode: _pinFocus,
                      enabled: !auth.busy,
                      obscureText: true,
                      style: theme.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'PIN / Password',
                        prefixIcon: Icon(Icons.password),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 28,
                      child: auth.error == null
                          ? null
                          : Text(
                              auth.error!,
                              key: const Key('loginError'),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.danger),
                            ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: auth.busy ? null : _submit,
                      child: auth.busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.busy
                          ? null
                          : ref.read(flowCoordinatorProvider).dismissPrompt,
                      child: const Text('Not now'),
                    ),
                    if (config.mockApi) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Demo mode: EMP001 / 1234',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                      TextButton(
                        onPressed: ref.read(flowCoordinatorProvider).exitApp,
                        child: const Text('Exit demo (Ctrl+Shift+F12)'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
