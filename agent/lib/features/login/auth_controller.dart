import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/api/api_client.dart';
import '../../data/models/models.dart';
import '../../services/logging.dart';

class AuthState {
  const AuthState({
    this.worker,
    this.busy = false,
    this.error,
    this.pendingReport = false,
  });

  /// The signed-in worker; null while the lock screen is showing login.
  final Worker? worker;
  final bool busy;
  final String? error;

  /// Yesterday's report must be submitted before anything else.
  final bool pendingReport;

  bool get isSignedIn => worker != null;
}

/// Login / sign-out for the lock screen. No widget code here.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String employeeId, String pin) async {
    if (state.busy) return;
    if (employeeId.trim().isEmpty || pin.isEmpty) {
      state = const AuthState(error: 'Enter your employee ID and PIN');
      return;
    }
    state = const AuthState(busy: true);
    try {
      final worker = await ref
          .read(authServiceProvider)
          .login(employeeId: employeeId, pin: pin);
      final pending = await ref.read(pendingReportProvider)();
      log.i('Signed in ${worker.employeeId}');
      state = AuthState(worker: worker, pendingReport: pending);
    } on ApiException catch (e) {
      log.w('Login failed: $e');
      state = AuthState(error: _message(e));
    } on Object catch (e, st) {
      log.e('Login error', error: e, stackTrace: st);
      state = const AuthState(error: 'Something went wrong. Try again.');
    }
  }

  /// Re-checks whether a report is still owed (after submitting one).
  Future<void> refreshPending() async {
    final pending = await ref.read(pendingReportProvider)();
    state = AuthState(worker: state.worker, pendingReport: pending);
  }

  /// Returns to the sign-in prompt (end of day, dismissed, hours ran out).
  void signOut({String? message}) {
    state = AuthState(error: message);
  }

  String _message(ApiException e) {
    if (e.isUnauthorized) return 'Invalid employee ID or PIN';
    if (e.isNetwork) {
      return 'Cannot reach the server. Check the network and try again.';
    }
    return e.message;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
