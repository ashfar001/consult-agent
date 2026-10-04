import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/common/placeholder_screen.dart';
import '../features/login/auth_controller.dart';
import '../features/login/login_screen.dart';
import '../features/project_select/project_select_screen.dart';

abstract final class Routes {
  static const lock = '/lock';
  static const projects = '/projects';
  static const pendingReport = '/pending-report';
  static const opening = '/opening';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth state to go_router's refresh mechanism.
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.lock,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = refresh.value;
      final at = state.matchedLocation;
      if (!auth.isSignedIn) return at == Routes.lock ? null : Routes.lock;
      if (auth.pendingReport && at != Routes.pendingReport) {
        return Routes.pendingReport;
      }
      if (at == Routes.lock) return Routes.projects;
      return null;
    },
    routes: [
      GoRoute(path: Routes.lock, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.projects,
        builder: (_, _) => const ProjectSelectScreen(),
      ),
      GoRoute(
        path: Routes.pendingReport,
        builder: (_, _) => const PlaceholderScreen(
          title: 'Pending report',
          message: 'Yesterday\'s report is required (phase 4).',
        ),
      ),
      GoRoute(
        path: Routes.opening,
        builder: (_, _) => const OpeningPlaceholderScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
