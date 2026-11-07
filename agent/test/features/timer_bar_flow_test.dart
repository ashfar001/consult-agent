import 'package:consult_agent/app/flow.dart';
import 'package:consult_agent/app/providers.dart';
import 'package:consult_agent/app/router.dart';
import 'package:consult_agent/app/theme.dart';
import 'package:consult_agent/config/app_config.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/services/device_info.dart';
import 'package:consult_agent/services/timer_dock_preferences.dart';
import 'package:consult_agent/services/window_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dock hover, focus, timeout, Hide, hotkey and edge switch', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(6, 104);
    addTearDown(tester.view.reset);

    final db = AgentDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final config = AppConfig.defaults(
      programDataDir: '/tmp',
      userProfileDir: '/tmp',
    ).withMockApi(true);
    final window = FakeWindowService();
    var now = DateTime(2026, 10, 5, 9);
    final container = ProviderContainer(
      overrides: [
        configProvider.overrideWithValue(config),
        dbProvider.overrideWithValue(db),
        deviceInfoProvider.overrideWithValue(
          const DeviceInfo(deviceId: 'dev-1', pcName: 'DRAFT-PC-01'),
        ),
        windowServiceProvider.overrideWithValue(window),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (_, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: buildTheme(),
          ),
        ),
      ),
    );

    final flow = container.read(flowCoordinatorProvider);
    await flow.showBar();
    await tester.pumpAndSettle();
    expect(window.modes, [WindowMode.bar]);
    expect(window.dockEdge.value, DockEdge.right);
    expect(find.text('Hide'), findsNothing);

    window.pointerInside = true;
    await tester.pump(const Duration(milliseconds: 50));
    tester.view.physicalSize = const Size(400, 104);
    await tester.pump();
    expect(window.collapses, [false]);
    expect(window.focusRequests, 0, reason: 'Hover must not activate the dock');
    expect(find.text('Upload'), findsOneWidget);

    await tester.tap(find.text('Move left'));
    await tester.pump();
    expect(window.dockEdge.value, DockEdge.left);
    expect(find.text('Move right'), findsOneWidget);

    window.pointerInside = false;
    window.keyboardFocus = true;
    await tester.pump(const Duration(milliseconds: 50));
    now = now.add(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 50));
    expect(window.collapses, [false]);

    window.keyboardFocus = false;
    await tester.pump(const Duration(milliseconds: 50));
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 50));
    expect(window.collapses, [false, true]);

    await flow.toggleControls();
    expect(window.collapses, [false, true, false]);
    expect(window.focusRequests, 1, reason: 'The hotkey enables keyboard use');

    window.pointerInside = true;
    await tester.tap(find.text('Hide'));
    tester.view.physicalSize = const Size(6, 104);
    await tester.pump();
    expect(window.collapses, [false, true, false, true]);
    expect(window.modes, [WindowMode.bar]);
    expect(find.text('Hide'), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(window.collapses, [false, true, false, true]);

    window.pointerInside = false;
    await tester.pump(const Duration(milliseconds: 50));
    window.pointerInside = true;
    await tester.pump(const Duration(milliseconds: 50));
    expect(window.collapses, [false, true, false, true, false]);

    await flow.showIdle();
    now = now.add(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 50));
    expect(window.collapses, [false, true, false, true, false]);
    await tester.pumpWidget(const SizedBox());
  });
}
