import 'dart:math';

import 'package:intl/intl.dart';

import '../models/models.dart';
import 'api_client.dart';

/// In-memory backend for running the agent with no server (`MOCK_API=true`).
///
/// Simulates latency and random network failures so the offline queue gets
/// exercised. Writes are idempotent by client UUID like the real server.
class MockApiClient implements ApiClient {
  MockApiClient({
    this.latencyMs = 500,
    this.failureRate = 0.15,
    Random? random,
  }) : _random = random ?? Random() {
    _seed();
  }

  /// Upper bound of simulated latency; each call waits 40–100% of it.
  final int latencyMs;

  /// Probability (0..1) that a call fails with a network error.
  final double failureRate;

  /// When true every call fails as if offline (handy in tests and demos).
  bool offline = false;

  final Random _random;

  static const _validEmployeeId = 'EMP001';
  static const _validPin = '1234';
  static const _token = 'mock-token-emp001';

  @override
  String? token;

  late final Worker worker;
  final Map<String, Project> _projects = {};
  final Map<String, List<RemoteFile>> _files = {};
  final Map<String, String> _sessionsByClientId = {};
  final Map<String, ({String projectId, DateTime startedAt})> _sessions = {};
  final Set<String> _seenHeartbeats = {};
  final Set<String> _seenWrites = {};
  final Map<String, ({String projectId, String path, int size})> _uploads = {};
  final Map<String, DailyReport> reports = {};
  final List<AgentEvent> events = [];
  final Map<String, int> _todayApps = {};
  final Map<String, int> _todayProjectActive = {};
  int _todayActive = 0;
  int _todayIdle = 0;
  int _nextId = 1000;

  /// Heartbeats accepted (after dedupe), for tests.
  int get acceptedHeartbeats => _seenHeartbeats.length;

  void _seed() {
    worker = const Worker(
      id: 'w-1',
      employeeId: _validEmployeeId,
      name: 'Arun Kumar',
      role: 'CAD Drafter',
    );
    const template = [
      '01_Survey',
      '02_Drawings',
      '03_Structural',
      '04_KSMART',
      '05_Exports',
      '06_Client-Docs',
    ];
    final projects = [
      Project(
        id: 'p-101',
        code: 'KP-101',
        name: 'Residential Villa, Kakkanad',
        client: 'Mr. Thomas Varghese',
        overrunMode: OverrunMode.allow,
        folderTemplate: template,
        myAllocatedHours: 40,
        myUsedSeconds: 12 * 3600,
        projectTotalHours: 70,
        projectUsedSeconds: 31 * 3600,
        tasks: const [
          ProjectTask(
            id: 't-1011',
            title: 'Ground floor plan',
            status: TaskStatus.inProgress,
            allocatedHours: 16,
          ),
          ProjectTask(
            id: 't-1012',
            title: 'Elevations & sections',
            status: TaskStatus.todo,
            allocatedHours: 14,
          ),
          ProjectTask(
            id: 't-1013',
            title: 'K-SMART permit drawings',
            status: TaskStatus.todo,
            allocatedHours: 10,
          ),
        ],
      ),
      Project(
        id: 'p-102',
        code: 'KP-102',
        name: 'Commercial Complex, Edappally',
        client: 'Marine Builders Pvt Ltd',
        overrunMode: OverrunMode.allow,
        folderTemplate: template,
        myAllocatedHours: 20,
        myUsedSeconds: 17 * 3600,
        projectTotalHours: 120,
        projectUsedSeconds: 88 * 3600,
        tasks: const [
          ProjectTask(
            id: 't-1021',
            title: 'Structural column layout',
            status: TaskStatus.inProgress,
            allocatedHours: 12,
          ),
          ProjectTask(
            id: 't-1022',
            title: 'BOQ in Excel',
            status: TaskStatus.todo,
            allocatedHours: 8,
          ),
        ],
      ),
      Project(
        id: 'p-103',
        code: 'KP-103',
        name: 'School Block, Aluva',
        client: 'St. Mary\'s Educational Trust',
        overrunMode: OverrunMode.block,
        folderTemplate: template,
        myAllocatedHours: 10,
        myUsedSeconds: 9 * 3600 + 55 * 60,
        projectTotalHours: 45,
        projectUsedSeconds: 40 * 3600,
        tasks: const [
          ProjectTask(
            id: 't-1031',
            title: 'Revit model update',
            status: TaskStatus.inProgress,
            allocatedHours: 6,
          ),
          ProjectTask(
            id: 't-1032',
            title: 'Fire exit plan',
            status: TaskStatus.todo,
            allocatedHours: 4,
          ),
        ],
      ),
    ];
    for (final p in projects) {
      _projects[p.id] = p;
    }

    RemoteFile f(String id, String path, int v, int size, [String? by]) =>
        RemoteFile(
          fileId: id,
          path: path,
          version: v,
          size: size,
          checkedOutBy: by,
          downloadUrl: 'mock://files/$id/v$v',
        );
    _files['p-101'] = [
      f('f-1', '02_Drawings/GF_Plan.dwg', 3, 2048),
      f('f-2', '01_Survey/Site_Survey.pdf', 1, 4096),
      f('f-3', '04_KSMART/Permit_Checklist.xlsx', 2, 1024),
    ];
    _files['p-102'] = [
      f('f-4', '03_Structural/Column_Layout.dwg', 5, 3072, 'Meera'),
      f('f-5', '05_Exports/BOQ.xlsx', 1, 1024),
    ];
    _files['p-103'] = [
      f('f-6', '02_Drawings/School_Block.rvt', 7, 8192),
    ];
  }

  /// Generates deterministic dummy content for a mock download URL.
  /// Used by the FolderManager when it sees a `mock://` URL (phase 3).
  static List<int> dummyContent(String downloadUrl, int size) {
    final header = 'ConsultAgent mock file $downloadUrl\n'.codeUnits;
    return List<int>.generate(
      size,
      (i) => i < header.length ? header[i] : 0x20 + (i % 90),
    );
  }

  Future<void> _simulate() async {
    if (latencyMs > 0) {
      final ms = (latencyMs * (0.4 + 0.6 * _random.nextDouble())).round();
      await Future<void>.delayed(Duration(milliseconds: ms));
    }
    if (offline || _random.nextDouble() < failureRate) {
      throw const ApiException.network('Simulated network failure');
    }
  }

  void _requireAuth() {
    if (token != _token) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }
  }

  Project _project(String id) =>
      _projects[id] ??
      (throw ApiException('Project $id not found', statusCode: 404));

  String _id(String prefix) => '$prefix-${_nextId++}';

  @override
  Future<DeviceStatus> registerDevice({
    required String pcName,
    required String deviceId,
  }) async {
    await _simulate();
    return DeviceStatus.approved;
  }

  @override
  Future<LoginResult> login({
    required String employeeId,
    required String pin,
    required String deviceId,
  }) async {
    await _simulate();
    if (employeeId.trim().toUpperCase() != _validEmployeeId ||
        pin != _validPin) {
      throw const ApiException(
        'Invalid employee ID or PIN',
        statusCode: 401,
      );
    }
    return LoginResult(token: _token, worker: worker);
  }

  @override
  Future<List<Project>> myProjects() async {
    await _simulate();
    _requireAuth();
    return _projects.values.toList();
  }

  @override
  Future<String> startSession({
    required String clientId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
  }) async {
    await _simulate();
    _requireAuth();
    _project(projectId);
    return _sessionsByClientId.putIfAbsent(clientId, () {
      final id = _id('s');
      _sessions[id] = (projectId: projectId, startedAt: startedAt);
      return id;
    });
  }

  @override
  Future<HeartbeatAck> sendHeartbeats(List<Heartbeat> heartbeats) async {
    await _simulate();
    _requireAuth();
    String? lastProjectId;
    for (final hb in heartbeats) {
      final session = _sessions[hb.sessionId];
      if (session == null) {
        throw ApiException(
          'Unknown session ${hb.sessionId}',
          statusCode: 422,
        );
      }
      lastProjectId = session.projectId;
      if (!_seenHeartbeats.add(hb.clientId)) continue;
      final p = _project(session.projectId);
      _projects[p.id] = p.copyWith(myUsedSeconds: p.myUsedSeconds + hb.activeSecs);
      _todayActive += hb.activeSecs;
      _todayIdle += hb.idleSecs;
      _todayProjectActive.update(
        p.id,
        (v) => v + hb.activeSecs,
        ifAbsent: () => hb.activeSecs,
      );
      hb.apps.forEach((app, secs) {
        _todayApps.update(app, (v) => v + secs, ifAbsent: () => secs);
      });
    }
    if (lastProjectId == null) {
      return const HeartbeatAck(
        myUsedSeconds: 0,
        myAllocatedHours: 0,
        overrun: false,
      );
    }
    final p = _project(lastProjectId);
    return HeartbeatAck(
      myUsedSeconds: p.myUsedSeconds,
      myAllocatedHours: p.myAllocatedHours,
      overrun: p.myUsedSeconds >= p.myAllocatedHours * 3600,
    );
  }

  @override
  Future<void> stopSession({
    required String sessionId,
    required DateTime endedAt,
    required bool unclean,
  }) async {
    await _simulate();
    _requireAuth();
    // Idempotent: stopping an already-stopped session is a no-op.
  }

  @override
  Future<List<RemoteFile>> projectFiles(String projectId) async {
    await _simulate();
    _requireAuth();
    _project(projectId);
    return List.of(_files[projectId] ?? const []);
  }

  ({String projectId, int index}) _findFile(String fileId) {
    for (final e in _files.entries) {
      final i = e.value.indexWhere((f) => f.fileId == fileId);
      if (i >= 0) return (projectId: e.key, index: i);
    }
    throw ApiException('File $fileId not found', statusCode: 404);
  }

  void _setCheckout(String fileId, String? by) {
    final loc = _findFile(fileId);
    final f = _files[loc.projectId]![loc.index];
    if (f.checkedOutBy != null &&
        f.checkedOutBy != worker.name &&
        by != null) {
      throw ApiException('In use by ${f.checkedOutBy}', statusCode: 409);
    }
    _files[loc.projectId]![loc.index] = RemoteFile(
      fileId: f.fileId,
      path: f.path,
      version: f.version,
      size: f.size,
      checkedOutBy: by,
      downloadUrl: f.downloadUrl,
    );
  }

  @override
  Future<void> checkoutFile(String fileId) async {
    await _simulate();
    _requireAuth();
    _setCheckout(fileId, worker.name);
  }

  @override
  Future<void> checkinFile(String fileId) async {
    await _simulate();
    _requireAuth();
    final loc = _findFile(fileId);
    if (_files[loc.projectId]![loc.index].checkedOutBy == worker.name) {
      _setCheckout(fileId, null);
    }
  }

  @override
  Future<UploadTarget> requestUploadUrl({
    required String clientId,
    required String projectId,
    required String path,
    required int size,
  }) async {
    await _simulate();
    _requireAuth();
    _project(projectId);
    final uploadId = 'u-$clientId';
    _uploads[uploadId] = (projectId: projectId, path: path, size: size);
    const partSize = 50 * 1024 * 1024;
    if (size > partSize) {
      final n = (size / partSize).ceil();
      return UploadTarget(
        uploadId: uploadId,
        parts: [for (var i = 1; i <= n; i++) 'mock://upload/$uploadId/$i'],
      );
    }
    return UploadTarget(uploadId: uploadId, url: 'mock://upload/$uploadId');
  }

  @override
  Future<FileVersionRef> confirmUpload({
    required String uploadId,
    required String note,
  }) async {
    await _simulate();
    _requireAuth();
    final up = _uploads[uploadId] ??
        (throw ApiException('Unknown upload $uploadId', statusCode: 404));
    final files = _files.putIfAbsent(up.projectId, () => []);
    final i = files.indexWhere((f) => f.path == up.path);
    if (_seenWrites.contains('confirm:$uploadId') && i >= 0) {
      return FileVersionRef(fileId: files[i].fileId, version: files[i].version);
    }
    _seenWrites.add('confirm:$uploadId');
    final RemoteFile next;
    if (i >= 0) {
      final f = files[i];
      next = RemoteFile(
        fileId: f.fileId,
        path: f.path,
        version: f.version + 1,
        size: up.size,
        checkedOutBy: f.checkedOutBy,
        downloadUrl: 'mock://files/${f.fileId}/v${f.version + 1}',
      );
      files[i] = next;
    } else {
      final id = _id('f');
      next = RemoteFile(
        fileId: id,
        path: up.path,
        version: 1,
        size: up.size,
        downloadUrl: 'mock://files/$id/v1',
      );
      files.add(next);
    }
    return FileVersionRef(fileId: next.fileId, version: next.version);
  }

  @override
  Future<void> completeTask({
    required String clientId,
    required String taskId,
    required String note,
  }) async {
    await _simulate();
    _requireAuth();
    if (!_seenWrites.add('task:$clientId')) return;
    for (final p in _projects.values) {
      if (p.tasks.any((t) => t.id == taskId)) {
        _projects[p.id] = p.copyWith(
          tasks: [
            for (final t in p.tasks)
              t.id == taskId ? t.copyWith(status: TaskStatus.completed) : t,
          ],
        );
        return;
      }
    }
    throw ApiException('Task $taskId not found', statusCode: 404);
  }

  @override
  Future<void> submitDailyReport(DailyReport report) async {
    await _simulate();
    _requireAuth();
    reports[DateFormat('yyyy-MM-dd').format(report.date)] = report;
  }

  @override
  Future<HoursToday> myHoursToday() async {
    await _simulate();
    _requireAuth();
    return HoursToday(
      activeSecs: _todayActive,
      idleSecs: _todayIdle,
      apps: Map.of(_todayApps),
      projects: [
        for (final p in _projects.values)
          ProjectHours(
            projectId: p.id,
            code: p.code,
            activeSecsToday: _todayProjectActive[p.id] ?? 0,
            myUsedSeconds: p.myUsedSeconds,
            myAllocatedHours: p.myAllocatedHours,
          ),
      ],
    );
  }

  @override
  Future<void> sendEvents(List<AgentEvent> events) async {
    await _simulate();
    _requireAuth();
    for (final e in events) {
      if (_seenWrites.add('event:${e.clientId}')) this.events.add(e);
    }
  }
}
