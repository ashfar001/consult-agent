import 'dart:math';

import 'package:consult_agent/app/app.dart';
import 'package:consult_agent/app/providers.dart';
import 'package:consult_agent/config/app_config.dart';
import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/services/device_info.dart';
import 'package:consult_agent/services/window_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrong PIN shows error; correct PIN shows project cards',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AgentDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final config = AppConfig.defaults(
      programDataDir: '/tmp',
      userProfileDir: '/tmp',
    ).mergeJson({'company_name': 'Test Consultants', 'mock_api': true});

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          configProvider.overrideWithValue(config),
          dbProvider.overrideWithValue(db),
          deviceInfoProvider.overrideWithValue(
            const DeviceInfo(deviceId: 'dev-1', pcName: 'DRAFT-PC-01'),
          ),
          windowServiceProvider.overrideWithValue(FakeWindowService()),
          apiClientProvider.overrideWithValue(
            MockApiClient(latencyMs: 0, failureRate: 0, random: Random(1)),
          ),
        ],
        child: const ConsultAgentApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Test Consultants'), findsOneWidget);
    expect(find.text('DRAFT-PC-01'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('employeeId')), 'EMP001');
    await tester.enterText(find.byKey(const Key('pin')), '9999');
    await tester.tap(find.text('Sign in'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Invalid employee ID or PIN'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pin')), '1234');
    await tester.tap(find.text('Sign in'));
    // Login and project load touch the (real, in-memory) DB.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(find.text('KP-101'), findsOneWidget);
    expect(find.text('KP-102'), findsOneWidget);
    expect(find.text('KP-103'), findsOneWidget);
    expect(find.text('Hello Arun Kumar'), findsOneWidget);

    // Unmount so the clock timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
