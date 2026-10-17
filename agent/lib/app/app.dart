import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flow.dart';
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
    return MaterialApp.router(
      title: 'ConsultAgent',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
