import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_exit_screen.dart';
import '../features/break/break_screen.dart';
import '../features/break/overtime_screen.dart';
import '../features/break/notice_screen.dart';
import '../features/end_day/end_day_screen.dart';
import '../features/login/auth_controller.dart';
import '../features/login/login_screen.dart';
import '../features/opening/opening_screen.dart';
import '../features/project_select/project_select_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/timer_bar/timer_bar_screen.dart';
import '../features/upload/upload_dialog.dart';

abstract final class Routes {
  static const idle = '/idle';
  static const prompt = '/prompt';
  static const projects = '/projects';
  static const opening = '/opening';
  static const bar = '/bar';
  static const breakRoute = '/break';
  static const overtime = '/overtime';
  static const notice = '/notice';
  static const upload = '/upload';
  static const endDay = '/end-day';
  static const summary = '/summary';
  static const pendingReport = '/pending-report';
  static const adminExit = '/admin-exit';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth state to go_router's refresh mechanism.
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.idle,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = refresh.value;
      final at = state.matchedLocation;
      const needSignIn = {
        Routes.projects,
        Routes.opening,
        Routes.pendingReport,
      };
      if (!auth.isSignedIn) {
        return needSignIn.contains(at) ? Routes.prompt : null;
      }
      if (at == Routes.prompt) {
        return auth.pendingReport ? Routes.pendingReport : Routes.projects;
      }
      if (auth.pendingReport && at == Routes.projects) {
        return Routes.pendingReport;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.idle,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(path: Routes.prompt, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.projects,
        builder: (_, _) => const ProjectSelectScreen(),
      ),
      GoRoute(path: Routes.opening, builder: (_, _) => const OpeningScreen()),
      GoRoute(path: Routes.bar, builder: (_, _) => const TimerBarScreen()),
      GoRoute(path: Routes.breakRoute, builder: (_, _) => const BreakScreen()),
      GoRoute(path: Routes.overtime, builder: (_, _) => const OvertimeScreen()),
      GoRoute(path: Routes.notice, builder: (_, _) => const NoticeScreen()),
      GoRoute(path: Routes.upload, builder: (_, _) => const UploadDialog()),
      GoRoute(
        path: Routes.endDay,
        builder: (_, _) => const EndDayScreen(pending: false),
      ),
      GoRoute(
        path: Routes.pendingReport,
        builder: (_, _) => const EndDayScreen(pending: true),
      ),
      GoRoute(path: Routes.summary, builder: (_, _) => const SummaryScreen()),
      GoRoute(
        path: Routes.adminExit,
        builder: (_, _) => const AdminExitScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
