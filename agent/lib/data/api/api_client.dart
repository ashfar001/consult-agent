import '../models/models.dart';

/// Failure talking to the backend.
///
/// [isNetwork] means the request may not have reached the server (offline,
/// timeout, DNS, 5xx gateway) and is safe to retry because every write is
/// idempotent via its client UUID. Otherwise the server rejected it.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  const ApiException.network([String message = 'Network unavailable'])
    : this(message, isNetwork: true);

  final String message;
  final int? statusCode;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  /// Should a queued write be retried later?
  bool get isRetryable =>
      isNetwork ||
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() =>
      'ApiException($message, status: $statusCode, network: $isNetwork)';
}

/// The agent's view of the backend contract. Implemented by
/// `HttpApiClient` (real) and `MockApiClient` (offline development).
///
/// Methods taking a `clientId` send it as `client_id` for server-side dedupe.
abstract interface class ApiClient {
  /// Sets the Bearer token used for subsequent calls (null clears it).
  set token(String? value);

  Future<DeviceStatus> registerDevice({
    required String pcName,
    required String deviceId,
  });

  Future<LoginResult> login({
    required String employeeId,
    required String pin,
    required String deviceId,
  });

  Future<List<Project>> myProjects();

  /// Returns the server session id.
  Future<String> startSession({
    required String clientId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
  });

  Future<HeartbeatAck> sendHeartbeats(List<Heartbeat> heartbeats);

  Future<void> stopSession({
    required String sessionId,
    required DateTime endedAt,
    required bool unclean,
  });

  Future<List<RemoteFile>> projectFiles(String projectId);

  Future<void> checkoutFile(String fileId);

  Future<void> checkinFile(String fileId);

  Future<UploadTarget> requestUploadUrl({
    required String clientId,
    required String projectId,
    required String path,
    required int size,
  });

  Future<FileVersionRef> confirmUpload({
    required String uploadId,
    required String note,
  });

  Future<void> completeTask({
    required String clientId,
    required String taskId,
    required String note,
  });

  Future<void> submitDailyReport(DailyReport report);

  Future<HoursToday> myHoursToday();

  Future<void> sendEvents(List<AgentEvent> events);
}
