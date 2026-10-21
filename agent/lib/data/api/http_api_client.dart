import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_client.dart';

/// dio-backed client for the real backend (`/agent/*`). Errors are mapped to
/// [ApiException]: no response -> network; any HTTP error -> status + detail.
class HttpApiClient implements ApiClient {
  HttpApiClient({required this.baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          ) {
    _dio.options.baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.headers['Accept'] = 'application/json';
    // Mapping is done here, not by dio's status validation.
    _dio.options.validateStatus = (_) => true;
  }

  final String baseUrl;
  final Dio _dio;

  String? _token;

  String? get token => _token;

  @override
  set token(String? value) {
    _token = value;
    if (value == null || value.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $value';
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Options? options,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        path,
        data: body,
        options: (options ?? Options()).copyWith(method: method),
      );
    } on DioException catch (e) {
      if (e.response != null) throw _fromResponse(e.response!);
      throw ApiException.network(e.message ?? '${e.error ?? e.type}');
    }
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) throw _fromResponse(res);
    return res.data;
  }

  ApiException _fromResponse(Response<dynamic> res) {
    final code = res.statusCode;
    final data = res.data;
    String? detail;
    if (data is Map && data['detail'] != null) {
      detail = data['detail'].toString();
    }
    return ApiException(detail ?? 'HTTP $code', statusCode: code);
  }

  Json _obj(dynamic data) =>
      data is Map<String, dynamic> ? data : <String, dynamic>{};

  @override
  Future<DeviceStatus> registerDevice({
    required String pcName,
    required String deviceId,
  }) async {
    final d = _obj(
      await _send(
        'POST',
        'agent/devices/register',
        body: {'device_id': deviceId, 'pc_name': pcName},
      ),
    );
    return deviceStatusFromString(asString(d['status']));
  }

  @override
  Future<LoginResult> login({
    required String employeeId,
    required String pin,
    required String deviceId,
  }) async => LoginResult.fromJson(
    _obj(
      await _send(
        'POST',
        'agent/login',
        body: {'employee_id': employeeId, 'pin': pin, 'device_id': deviceId},
      ),
    ),
  );

  @override
  Future<List<Project>> myProjects() async => asJsonList(
    await _send('GET', 'agent/my-projects'),
  ).map(Project.fromJson).toList();

  @override
  Future<String> startSession({
    required String clientId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
  }) async {
    final d = _obj(
      await _send(
        'POST',
        'agent/sessions/start',
        body: {
          'client_id': clientId,
          'project_id': projectId,
          'task_id': taskId,
          'started_at': isoUtc(startedAt),
        },
      ),
    );
    return asString(d['session_id']);
  }

  @override
  Future<HeartbeatAck> sendHeartbeats(List<Heartbeat> heartbeats) async =>
      HeartbeatAck.fromJson(
        _obj(
          await _send(
            'POST',
            'agent/sessions/heartbeats',
            body: heartbeats.map((h) => h.toJson()).toList(),
          ),
        ),
      );

  @override
  Future<void> stopSession({
    required String sessionId,
    required DateTime endedAt,
    required bool unclean,
  }) async {
    await _send(
      'POST',
      'agent/sessions/$sessionId/stop',
      body: {'ended_at': isoUtc(endedAt), 'unclean': unclean},
    );
  }

  @override
  Future<List<RemoteFile>> projectFiles(String projectId) async => asJsonList(
    await _send('GET', 'agent/projects/$projectId/files'),
  ).map(RemoteFile.fromJson).toList();

  @override
  Future<void> checkoutFile(String fileId) async {
    await _send('POST', 'agent/files/$fileId/checkout', body: {});
  }

  @override
  Future<void> checkinFile(String fileId) async {
    await _send('POST', 'agent/files/$fileId/checkin', body: {});
  }

  @override
  Future<UploadTarget> requestUploadUrl({
    required String clientId,
    required String projectId,
    required String path,
    required int size,
  }) async => UploadTarget.fromJson(
    _obj(
      await _send(
        'POST',
        'agent/files/upload-url',
        body: {
          'client_id': clientId,
          'project_id': projectId,
          'path': path,
          'size': size,
        },
      ),
    ),
  );

  @override
  Future<FileVersionRef> confirmUpload({
    required String uploadId,
    required String note,
  }) async => FileVersionRef.fromJson(
    _obj(
      await _send(
        'POST',
        'agent/files/confirm',
        body: {'upload_id': uploadId, 'note': note},
      ),
    ),
  );

  @override
  Future<void> completeTask({
    required String clientId,
    required String taskId,
    required String note,
  }) async {
    await _send(
      'POST',
      'agent/tasks/complete',
      body: {'client_id': clientId, 'task_id': taskId, 'note': note},
    );
  }

  @override
  Future<void> submitDailyReport(DailyReport report) async {
    await _send('POST', 'agent/daily-report', body: report.toJson());
  }

  @override
  Future<HoursToday> myHoursToday() async =>
      HoursToday.fromJson(_obj(await _send('GET', 'agent/my-hours/today')));

  @override
  Future<void> sendEvents(List<AgentEvent> events) async {
    await _send(
      'POST',
      'agent/events',
      body: events.map((e) => e.toJson()).toList(),
    );
  }
}
