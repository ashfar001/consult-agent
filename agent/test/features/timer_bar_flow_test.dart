import 'package:consult_agent/app/flow.dart';
import 'package:consult_agent/app/providers.dart';
import 'package:consult_agent/app/router.dart';
import 'package:consult_agent/app/theme.dart';
import 'package:consult_agent/config/app_config.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/services/device_info.dart';
import 'package:consult_agent/services/win32/cursor_source.dart';
import 'package:consult_agent/services/window_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hide, hover, timeout and hotkey keep the timer bar reachable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 104);
    addTearDown(tester.view.reset);

    final db = AgentDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final config = AppConfig.defaults(
      programDataDir: '/tmp',
      userProfileDir: '/tmp',
    ).withMockApi(true);
    final window = FakeWindowService();
    final cursor = FakeCursorSource(const Offset(600, 80));
    var now = DateTime(2026, 10, 5, 9);
    final app = Consumer(
      builder: (_, ref, _) => MaterialApp.router(
        routerConfig: ref.watch(routerProvider),
        theme: buildTheme(),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(config),
          dbProvider.overrideWithValue(db),
          deviceInfoProvider.overrideWithValue(
            const DeviceInfo(deviceId: 'dev-1', pcName: 'DRAFT-PC-01'),
          ),
          windowServiceProvider.overrideWithValue(window),
          cursorSourceProvider.overrideWithValue(cursor),
          clockProvider.overrideWithValue(() => now),
        ],
        child: app,
      ),
    );

    final flow = ProviderScope.containerOf(
      tester.element(find.byWidget(app)),
    ).read(flowCoordinatorProvider);
    await flow.showBar();
    await tester.pumpAndSettle();
    expect(window.modes, [WindowMode.bar]);
    expect(find.text('Hide'), findsOneWidget);

    await tester.tap(find.text('Hide'));
    tester.view.physicalSize = const Size(400, 6);
    await tester.pump();
    expect(window.collapses, [true]);
    expect(window.modes, [WindowMode.bar]);
    expect(find.text('Hide'), findsNothing);

    cursor.value = const Offset(600, 2);
    await tester.pump(const Duration(milliseconds: 100));
    tester.view.physicalSize = const Size(400, 104);
    await tester.pump();
    expect(window.collapses, [true, false]);
    expect(find.text('Upload'), findsOneWidget);

    cursor.value = const Offset(100, 500);
    await tester.pump(const Duration(milliseconds: 100));
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(window.collapses, [true, false, true]);

    await flow.toggleControls();
    expect(window.collapses, [true, false, true, false]);
    await flow.showIdle();
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(window.collapses, [true, false, true, false]);

    await tester.pumpWidget(const SizedBox());
  });
}
