import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:consult_agent/data/api/api_client.dart';
import 'package:consult_agent/data/api/http_api_client.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Req {
  _Req(this.method, this.uri, this.headers, this.body);
  final String method;
  final Uri uri;
  final Map<String, dynamic> headers;
  final Object? body;
}

class _FakeAdapter implements HttpClientAdapter {
  final requests = <_Req>[];
  int status = 200;
  Object? response = <String, dynamic>{};
  bool failConnection = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object? body;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final c in requestStream) {
        bytes.addAll(c);
      }
      if (bytes.isNotEmpty) body = jsonDecode(utf8.decode(bytes));
    }
    requests.add(
      _Req(options.method, options.uri, Map.of(options.headers), body),
    );
    if (failConnection) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late HttpApiClient client;

  setUp(() {
    adapter = _FakeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    client = HttpApiClient(baseUrl: 'http://srv:8000', dio: dio);
  });

  test('login success parses token and sends body', () async {
    adapter.response = {
      'token': 'tok',
      'worker': {'id': 'w1', 'name': 'Ann', 'employee_id': 'E1'},
    };
    final r = await client.login(
      employeeId: 'E1',
      pin: '1234',
      deviceId: 'dev',
    );
    expect(r.token, 'tok');
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.uri.toString(), 'http://srv:8000/agent/login');
    expect(req.body, {'employee_id': 'E1', 'pin': '1234', 'device_id': 'dev'});
  });

  test('token setter adds Bearer header', () async {
    client.token = 'abc';
    adapter.response = <dynamic>[];
    await client.myProjects();
    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('401 maps to isUnauthorized with detail', () async {
    adapter.status = 401;
    adapter.response = {'detail': 'Bad credentials'};
    await expectLater(
      client.login(employeeId: 'E1', pin: 'x', deviceId: 'd'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', true)
            .having((e) => e.message, 'message', 'Bad credentials')
            .having((e) => e.isNetwork, 'isNetwork', false),
      ),
    );
  });

  test('connection error maps to network', () async {
    adapter.failConnection = true;
    await expectLater(
      client.myProjects(),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'net', true)),
    );
  });

  test('startSession returns session_id', () async {
    adapter.response = {'session_id': 'srv-1'};
    final id = await client.startSession(
      clientId: 'c1',
      projectId: 'p1',
      taskId: 't1',
      startedAt: DateTime.utc(2026, 1, 2, 3),
    );
    expect(id, 'srv-1');
    final req = adapter.requests.single;
    expect(req.uri.path, '/agent/sessions/start');
    expect((req.body as Map)['started_at'], '2026-01-02T03:00:00.000Z');
  });

  test('sendHeartbeats posts a JSON list', () async {
    adapter.response = {
      'my_used_seconds': 60,
      'my_allocated_hours': 2,
      'overrun': false,
    };
    final ack = await client.sendHeartbeats([
      Heartbeat(
        clientId: 'h1',
        sessionId: 's1',
        from: DateTime.utc(2026, 1, 1, 0, 0),
        to: DateTime.utc(2026, 1, 1, 0, 1),
        activeSecs: 50,
        idleSecs: 10,
        apps: const {'cad': 50},
      ),
    ]);
    expect(ack.myUsedSeconds, 60);
    final req = adapter.requests.single;
    expect(req.uri.path, '/agent/sessions/heartbeats');
    final body = req.body as List;
    expect(body, hasLength(1));
    expect((body.first as Map)['client_id'], 'h1');
    expect((body.first as Map)['apps'], {'cad': 50});
  });

  test('stopSession posts to sessions/<id>/stop', () async {
    await client.stopSession(
      sessionId: 'abc',
      endedAt: DateTime.utc(2026, 1, 1),
      unclean: true,
    );
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.uri.path, '/agent/sessions/abc/stop');
    expect((req.body as Map)['unclean'], true);
  });
}
