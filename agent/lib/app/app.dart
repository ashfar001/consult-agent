import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flow.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class ConsultAgentApp extends ConsumerStatefulWidget {
  const ConsultAgentApp({super.key});

  @override
  ConsumerState<ConsultAgentApp> createState() => _ConsultAgentAppState();
}

class _ConsultAgentAppState extends ConsumerState<ConsultAgentApp> {
  @override
  void initState() {
    super.initState();
    // Starts watching for CAD apps once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flowCoordinatorProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(configProvider).mockApi;
    return MaterialApp.router(
      title: 'ConsultAgent',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => CallbackShortcuts(
        bindings: {
          // Demo builds only: a way out, since there is no tray icon.
          if (demo)
            const SingleActivator(
              LogicalKeyboardKey.f12,
              control: true,
              shift: true,
            ): ref.read(flowCoordinatorProvider).exitApp,
        },
        child: Focus(autofocus: true, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
