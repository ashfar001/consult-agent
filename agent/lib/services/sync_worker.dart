import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../data/api/api_client.dart';
import '../data/db/database.dart';
import '../data/models/models.dart';
import 'logging.dart';

/// Outbox row kinds drained by [SyncWorker].
abstract final class OutboxKind {
  static const sessionStart = 'session_start';
  static const sessionStop = 'session_stop';
  static const event = 'event';
  static const taskComplete = 'task_complete';
  static const dailyReport = 'daily_report';
}

/// Server's view of a worker's hours on a project, after a heartbeat batch.
typedef SyncAck = ({String projectId, int usedSecs});

/// Drains the local SQLite queue to the API.
///
/// Order each pass: session starts, then heartbeats (per session), then the
/// remaining outbox rows (stops wait until their heartbeats are synced).
/// Everything is already in SQLite before it gets here, so a failed pass
/// loses nothing; it backs off and tries again.
class SyncWorker {
  SyncWorker({
    required this.db,
    required this.api,
    required this.clock,
    this.interval = const Duration(seconds: 30),
    this.batchSize = 50,
    Random? random,
  }) : _random = random ?? Random();

  final AgentDatabase db;
  final ApiClient api;
  final DateTime Function() clock;
  final Duration interval;
  final int batchSize;
  final Random _random;

  final _acks = StreamController<SyncAck>.broadcast();
  final _online = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _running = false;
  int _failures = 0;
  DateTime? _backoffUntil;
  bool _isOnline = true;

  Stream<SyncAck> get acks => _acks.stream;
  Stream<bool> get onlineChanges => _online.stream;
  bool get isOnline => _isOnline;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => kick());
    kick();
  }

  void kick() => unawaited(syncOnce());

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _acks.close();
    _online.close();
  }

  /// Seconds to wait after [failures] consecutive failures (5 s → 5 min).
  static int backoffSecs(int failures, double jitter) {
    final base = min(300, 5 * pow(2, max(0, failures - 1)).toInt());
    return max(1, (base * jitter).round());
  }

  /// One sync pass. Returns true if everything due was sent.
  Future<bool> syncOnce({bool ignoreBackoff = false}) async {
    if (_running) return false;
    final now = clock();
    if (!ignoreBackoff &&
        _backoffUntil != null &&
        now.isBefore(_backoffUntil!)) {
      return false;
    }
    _running = true;
    try {
      await _sendSessionStarts();
      await _sendHeartbeats();
      await _sendOutbox();
      _failures = 0;
      _backoffUntil = null;
      _setOnline(true);
      return true;
    } on ApiException catch (e) {
      _failures++;
      final jitter = 0.8 + _random.nextDouble() * 0.4;
      _backoffUntil = clock().add(
        Duration(seconds: backoffSecs(_failures, jitter)),
      );
      if (e.isNetwork) _setOnline(false);
      log.w('Sync paused: $e');
      return false;
    } finally {
      _running = false;
    }
  }

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    if (!_online.isClosed) _online.add(value);
  }

  /// Runs one outbox item; permanent rejections are parked, transient ones
  /// (network, 5xx, 401) abort the pass so it is retried with backoff.
  Future<void> _attempt(OutboxRow row, Future<void> Function() send) async {
    try {
      await send();
      await db.outboxDao.markDone(row.id);
    } on ApiException catch (e) {
      if (e.isRetryable || e.isUnauthorized) rethrow;
      log.e('Dropping ${row.kind} ${row.clientId}: $e');
      await db.outboxDao.markFailed(
        row.id,
        e.toString(),
        clock().add(const Duration(days: 365)),
      );
    }
  }

  Future<void> _sendSessionStarts() async {
    final rows = await db.outboxDao.due(clock(), limit: 100);
    for (final row in rows.where((r) => r.kind == OutboxKind.sessionStart)) {
      final p = jsonDecode(row.payloadJson) as Json;
      await _attempt(row, () async {
        final serverId = await api.startSession(
          clientId: row.clientId,
          projectId: asString(p['project_id']),
          taskId: asString(p['task_id']),
          startedAt: asDate(p['started_at']),
        );
        await db.sessionDao.setServerId(row.clientId, serverId);
      });
    }
  }

  Future<void> _sendHeartbeats() async {
    while (true) {
      final pending = await db.sessionDao.sendableHeartbeats(limit: batchSize);
      if (pending.isEmpty) return;
      // One request per session so the ack maps to a single project.
      final first = pending.first.session;
      final batch = pending.where((e) => e.session.localId == first.localId);
      final beats = [
        for (final e in batch)
          Heartbeat(
            clientId: e.hb.clientId,
            sessionId: first.serverId!,
            from: e.hb.fromTime,
            to: e.hb.toTime,
            activeSecs: e.hb.activeSecs,
            idleSecs: e.hb.idleSecs,
            apps: asIntMap(jsonDecode(e.hb.appsJson)),
          ),
      ];
      final HeartbeatAck ack;
      try {
        ack = await api.sendHeartbeats(beats);
      } on ApiException catch (e) {
        if (e.isRetryable || e.isUnauthorized) rethrow;
        // Server doesn't know this session; keep the rows, try again later.
        log.e('Heartbeats rejected for ${first.localId}: $e');
        throw ApiException(e.message, statusCode: 503);
      }
      await db.sessionDao.markHeartbeatsSynced([
        for (final b in beats) b.clientId,
      ], clock());
      if (!_acks.isClosed) {
        _acks.add((projectId: first.projectId, usedSecs: ack.myUsedSeconds));
      }
    }
  }

  Future<void> _sendOutbox() async {
    final rows = await db.outboxDao.due(clock(), limit: 100);
    for (final row in rows) {
      final p = jsonDecode(row.payloadJson) as Json;
      switch (row.kind) {
        case OutboxKind.sessionStop:
          final local = asString(p['local_id']);
          final session = await db.sessionDao.byId(local);
          if (session?.serverId == null ||
              await db.sessionDao.hasUnsyncedHeartbeats(local)) {
            continue; // wait for start + heartbeats
          }
          await _attempt(
            row,
            () => api.stopSession(
              sessionId: session!.serverId!,
              endedAt: asDate(p['ended_at']),
              unclean: p['unclean'] == true,
            ),
          );
        case OutboxKind.event:
          await _attempt(
            row,
            () => api.sendEvents([
              AgentEvent(
                clientId: row.clientId,
                type: asString(p['type']),
                at: asDate(p['at']),
                data: (p['data'] as Json?) ?? const {},
              ),
            ]),
          );
        case OutboxKind.taskComplete:
          await _attempt(
            row,
            () => api.completeTask(
              clientId: row.clientId,
              taskId: asString(p['task_id']),
              note: asString(p['note']),
            ),
          );
        case OutboxKind.dailyReport:
          await _attempt(
            row,
            () => api.submitDailyReport(DailyReport.fromJson(p)),
          );
        default:
          break;
      }
    }
  }
}
