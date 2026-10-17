import 'json_utils.dart';

enum SessionStatus { open, closed, unclean }

/// A local work session. [localId] is the client UUID sent as `client_id`
/// on `sessions/start`; [serverId] arrives once that call syncs.
class WorkSession {
  const WorkSession({
    required this.localId,
    required this.projectId,
    required this.taskId,
    required this.startedAt,
    required this.status,
    this.serverId,
    this.endedAt,
    this.lastHeartbeatAt,
  });

  final String localId;
  final String? serverId;
  final String projectId;
  final String taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? lastHeartbeatAt;
  final SessionStatus status;
}

/// One 60-second (or shorter, at session edges) accounting slice.
class Heartbeat {
  const Heartbeat({
    required this.clientId,
    required this.sessionId,
    required this.from,
    required this.to,
    required this.activeSecs,
    required this.idleSecs,
    required this.apps,
  });

  factory Heartbeat.fromJson(Json json) => Heartbeat(
    clientId: asString(json['client_id']),
    sessionId: asString(json['session_id']),
    from: asDate(json['from']),
    to: asDate(json['to']),
    activeSecs: asInt(json['active_secs']),
    idleSecs: asInt(json['idle_secs']),
    apps: asIntMap(json['apps']),
  );

  final String clientId;

  /// Server session id once known.
  final String sessionId;
  final DateTime from;
  final DateTime to;
  final int activeSecs;
  final int idleSecs;

  /// Active seconds per classified app name.
  final Map<String, int> apps;

  Json toJson() => {
    'client_id': clientId,
    'session_id': sessionId,
    'from': isoUtc(from),
    'to': isoUtc(to),
    'active_secs': activeSecs,
    'idle_secs': idleSecs,
    'apps': apps,
  };
}

/// Response of `POST /agent/sessions/heartbeats`.
class HeartbeatAck {
  const HeartbeatAck({
    required this.myUsedSeconds,
    required this.myAllocatedHours,
    required this.overrun,
  });

  factory HeartbeatAck.fromJson(Json json) => HeartbeatAck(
    myUsedSeconds: asInt(json['my_used_seconds']),
    myAllocatedHours: asDouble(json['my_allocated_hours']),
    overrun: json['overrun'] == true,
  );

  final int myUsedSeconds;
  final double myAllocatedHours;
  final bool overrun;
}

/// Event type strings for `POST /agent/events`.
abstract final class AgentEventType {
  static const agentRestarted = 'agent_restarted';
  static const uncleanSession = 'unclean_session';
  static const breakStart = 'break_start';
  static const breakEnd = 'break_end';
  static const overtimeStart = 'overtime_start';
  static const workdayEnd = 'workday_end';
  static const adminExit = 'admin_exit';
  static const adminExitFailed = 'admin_exit_failed';
}

class AgentEvent {
  const AgentEvent({
    required this.clientId,
    required this.type,
    required this.at,
    this.data = const {},
  });

  final String clientId;
  final String type;
  final DateTime at;
  final Json data;

  Json toJson() => {
    'client_id': clientId,
    'type': type,
    'at': isoUtc(at),
    'data': data,
  };
}
