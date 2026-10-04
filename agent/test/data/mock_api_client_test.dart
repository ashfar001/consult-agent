import 'dart:math';

import 'package:consult_agent/data/api/api_client.dart';
import 'package:consult_agent/data/api/mock_api_client.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

MockApiClient _reliable() =>
    MockApiClient(latencyMs: 0, failureRate: 0, random: Random(1));

Future<MockApiClient> _signedIn() async {
  final api = _reliable();
  final r = await api.login(employeeId: 'EMP001', pin: '1234', deviceId: 'd');
  api.token = r.token;
  return api;
}

void main() {
  test('login succeeds with seeded credentials (case-insensitive id)', () async {
    final api = _reliable();
    final r = await api.login(employeeId: 'emp001', pin: '1234', deviceId: 'd');
    expect(r.worker.employeeId, 'EMP001');
    expect(r.token, isNotEmpty);
  });

  test('login with wrong PIN is a 401', () async {
    final api = _reliable();
    expect(
      () => api.login(employeeId: 'EMP001', pin: '0000', deviceId: 'd'),
      throwsA(
        isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue),
      ),
    );
  });

  test('calls without a token are rejected', () async {
    expect(
      _reliable().myProjects(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('seeds three projects including a near-exhausted block project',
      () async {
    final projects = await (await _signedIn()).myProjects();
    expect(projects.map((p) => p.code), ['KP-101', 'KP-102', 'KP-103']);
    final block = projects.singleWhere((p) => p.overrunMode == OverrunMode.block);
    expect(block.myUsedSeconds, lessThan(block.myAllocatedHours * 3600));
    expect(
      block.myUsedSeconds,
      greaterThan(block.myAllocatedHours * 3600 * 0.95),
    );
    expect(projects.every((p) => p.tasks.isNotEmpty), isTrue);
  });

  test('startSession is idempotent by client id', () async {
    final api = await _signedIn();
    final now = DateTime(2026, 10, 4, 9);
    final a = await api.startSession(
      clientId: 'c1',
      projectId: 'p-101',
      taskId: 't-1011',
      startedAt: now,
    );
    final b = await api.startSession(
      clientId: 'c1',
      projectId: 'p-101',
      taskId: 't-1011',
      startedAt: now,
    );
    expect(a, b);
  });

  test('heartbeats are deduped by client id', () async {
    final api = await _signedIn();
    final start = DateTime(2026, 10, 4, 9);
    final sessionId = await api.startSession(
      clientId: 'c1',
      projectId: 'p-101',
      taskId: 't-1011',
      startedAt: start,
    );
    final before = (await api.myProjects())
        .singleWhere((p) => p.id == 'p-101')
        .myUsedSeconds;
    final hb = Heartbeat(
      clientId: 'hb-1',
      sessionId: sessionId,
      from: start,
      to: start.add(const Duration(seconds: 60)),
      activeSecs: 50,
      idleSecs: 10,
      apps: const {'AutoCAD': 50},
    );

    final first = await api.sendHeartbeats([hb]);
    final second = await api.sendHeartbeats([hb, hb]);

    expect(first.myUsedSeconds, before + 50);
    expect(second.myUsedSeconds, before + 50);
    expect(api.acceptedHeartbeats, 1);
    final today = await api.myHoursToday();
    expect(today.activeSecs, 50);
    expect(today.idleSecs, 10);
    expect(today.apps, {'AutoCAD': 50});
  });

  test('heartbeat ack reports overrun once allocation is used', () async {
    final api = await _signedIn();
    final start = DateTime(2026, 10, 4, 9);
    final sessionId = await api.startSession(
      clientId: 'c2',
      projectId: 'p-103',
      taskId: 't-1031',
      startedAt: start,
    );
    final ack = await api.sendHeartbeats([
      Heartbeat(
        clientId: 'hb-x',
        sessionId: sessionId,
        from: start,
        to: start.add(const Duration(minutes: 5)),
        activeSecs: 300,
        idleSecs: 0,
        apps: const {},
      ),
    ]);
    expect(ack.overrun, isTrue);
  });

  test('offline flag fails every call as a retryable network error', () async {
    final api = await _signedIn();
    api.offline = true;
    expect(
      api.myProjects(),
      throwsA(isA<ApiException>().having((e) => e.isRetryable, 'retry', isTrue)),
    );
  });

  test('failure rate injects network errors', () async {
    final api = MockApiClient(latencyMs: 0, failureRate: 1, random: Random(1));
    expect(
      api.login(employeeId: 'EMP001', pin: '1234', deviceId: 'd'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'net', isTrue)),
    );
  });

  test('checkout of a file held by someone else is refused', () async {
    final api = await _signedIn();
    final files = await api.projectFiles('p-102');
    final held = files.singleWhere((f) => f.checkedOutBy != null);
    expect(held.checkedOutBy, 'Meera');
    expect(
      api.checkoutFile(held.fileId),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('upload confirm creates a new version, idempotently', () async {
    final api = await _signedIn();
    final target = await api.requestUploadUrl(
      clientId: 'up-1',
      projectId: 'p-101',
      path: '02_Drawings/GF_Plan.dwg',
      size: 100,
    );
    expect(target.isMultipart, isFalse);
    final v1 = await api.confirmUpload(uploadId: target.uploadId, note: 'n');
    final v2 = await api.confirmUpload(uploadId: target.uploadId, note: 'n');
    expect(v1.version, 4);
    expect(v2.version, 4);

    final big = await api.requestUploadUrl(
      clientId: 'up-2',
      projectId: 'p-101',
      path: 'big.rvt',
      size: 120 * 1024 * 1024,
    );
    expect(big.parts, hasLength(3));
  });
}
