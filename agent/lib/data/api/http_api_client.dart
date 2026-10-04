import '../models/models.dart';
import 'api_client.dart';

/// dio-backed client for the real backend. Implemented in phase 6; until then
/// run with `MOCK_API=true`.
class HttpApiClient implements ApiClient {
  HttpApiClient({required this.baseUrl});

  final String baseUrl;

  @override
  String? token;

  Never _todo() => throw UnimplementedError(
        'HttpApiClient is not implemented yet; set MOCK_API=true',
      );

  @override
  Future<DeviceStatus> registerDevice({
    required String pcName,
    required String deviceId,
  }) =>
      _todo();

  @override
  Future<LoginResult> login({
    required String employeeId,
    required String pin,
    required String deviceId,
  }) =>
      _todo();

  @override
  Future<List<Project>> myProjects() => _todo();

  @override
  Future<String> startSession({
    required String clientId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
  }) =>
      _todo();

  @override
  Future<HeartbeatAck> sendHeartbeats(List<Heartbeat> heartbeats) => _todo();

  @override
  Future<void> stopSession({
    required String sessionId,
    required DateTime endedAt,
    required bool unclean,
  }) =>
      _todo();

  @override
  Future<List<RemoteFile>> projectFiles(String projectId) => _todo();

  @override
  Future<void> checkoutFile(String fileId) => _todo();

  @override
  Future<void> checkinFile(String fileId) => _todo();

  @override
  Future<UploadTarget> requestUploadUrl({
    required String clientId,
    required String projectId,
    required String path,
    required int size,
  }) =>
      _todo();

  @override
  Future<FileVersionRef> confirmUpload({
    required String uploadId,
    required String note,
  }) =>
      _todo();

  @override
  Future<void> completeTask({
    required String clientId,
    required String taskId,
    required String note,
  }) =>
      _todo();

  @override
  Future<void> submitDailyReport(DailyReport report) => _todo();

  @override
  Future<HoursToday> myHoursToday() => _todo();

  @override
  Future<void> sendEvents(List<AgentEvent> events) => _todo();
}
