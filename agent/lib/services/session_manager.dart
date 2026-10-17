import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../app/providers.dart';
import '../data/db/database.dart';
import '../data/models/models.dart';
import '../domain/activity_accumulator.dart';
import '../domain/app_classifier.dart';
import '../domain/break_ledger.dart';
import '../domain/hour_limits.dart';
import '../domain/workday.dart';
import 'sync_worker.dart';

enum TrackStatus { none, active, idle, onBreak, workdayEnded }

class SessionState {
  const SessionState({
    this.status = TrackStatus.none,
    this.session,
    this.project,
    this.task,
    this.overtime = false,
    this.todayActiveSecs = 0,
    this.serverUsedSecs = 0,
    this.unsyncedSecs = 0,
    this.breakTakenSecs = 0,
    this.breakRemainingSecs = 0,
    this.breakPieces = 0,
    this.overrun = false,
    this.notice,
    this.blockMessage,
  });

  final TrackStatus status;
  final WorkSession? session;
  final Project? project;
  final ProjectTask? task;

  /// The current (or just ended) session is overtime.
  final bool overtime;

  /// Active seconds today across all sessions, including the unsaved slice.
  final int todayActiveSecs;
  final int serverUsedSecs;

  /// Local normal-hours active seconds the server hasn't acknowledged yet.
  final int unsyncedSecs;
  final int breakTakenSecs;
  final int breakRemainingSecs;
  final int breakPieces;
  final bool overrun;

  /// One-shot message for the UI (80% warning); cleared by [clearNotice].
  final String? notice;

  /// Set when a block-mode project ran out of hours.
  final String? blockMessage;

  bool get hasSession => session != null;

  HourUsage? get usage => project == null
      ? null
      : HourUsage(
          allocatedSecs: (project!.myAllocatedHours * 3600).round(),
          serverUsedSecs: serverUsedSecs,
          unsyncedSecs: overtime ? 0 : unsyncedSecs,
        );

  SessionState copyWith({
    TrackStatus? status,
    WorkSession? Function()? session,
    Project? Function()? project,
    ProjectTask? Function()? task,
    bool? overtime,
    int? todayActiveSecs,
    int? serverUsedSecs,
    int? unsyncedSecs,
    int? breakTakenSecs,
    int? breakRemainingSecs,
    int? breakPieces,
    bool? overrun,
    String? Function()? notice,
    String? Function()? blockMessage,
  }) =>
      SessionState(
        status: status ?? this.status,
        session: session != null ? session() : this.session,
        project: project != null ? project() : this.project,
        task: task != null ? task() : this.task,
        overtime: overtime ?? this.overtime,
        todayActiveSecs: todayActiveSecs ?? this.todayActiveSecs,
        serverUsedSecs: serverUsedSecs ?? this.serverUsedSecs,
        unsyncedSecs: unsyncedSecs ?? this.unsyncedSecs,
        breakTakenSecs: breakTakenSecs ?? this.breakTakenSecs,
        breakRemainingSecs: breakRemainingSecs ?? this.breakRemainingSecs,
        breakPieces: breakPieces ?? this.breakPieces,
        overrun: overrun ?? this.overrun,
        notice: notice != null ? notice() : this.notice,
        blockMessage: blockMessage != null ? blockMessage() : this.blockMessage,
      );
}

/// Owns the worker's current session: samples activity, writes heartbeats to
/// SQLite, enforces hour limits, and runs breaks and the 5 PM cut-off.
class SessionManager extends Notifier<SessionState> {
  static const _uuid = Uuid();
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  late final AgentDatabase _db;
  late final DateTime Function() _clock;
  late final WorkdayClock _workday;
  late final int _breakAllowance;
  late final int _breakMaxPieces;
  late final int _pollSecs;
  late final ActivityAccumulator _acc;

  Timer? _timer;
  bool _busy = false;
  bool _warned = false;
  String? _workerId;

  @override
  SessionState build() {
    _db = ref.read(dbProvider);
    _clock = ref.read(clockProvider);
    final cfg = ref.read(configProvider);
    _workday = WorkdayClock(cfg.workdayEnd);
    _breakAllowance = cfg.breakAllowanceSecs;
    _breakMaxPieces = cfg.breakMaxPieces;
    _pollSecs = cfg.pollIntervalSecs;
    _acc = ActivityAccumulator(
      idleThresholdSecs: cfg.idleThresholdSecs,
      sliceSecs: cfg.heartbeatIntervalSecs,
    );
    final sub = ref.read(syncWorkerProvider).acks.listen(_onAck);
    ref.onDispose(() {
      sub.cancel();
      _timer?.cancel();
    });
    return const SessionState();
  }

  // ---------------------------------------------------------------- start

  /// Starts tracking [task] on [project]. After the work day ends the session
  /// is created as overtime.
  Future<void> start({
    required String workerId,
    required Project project,
    required ProjectTask task,
  }) async {
    if (state.hasSession) return;
    _workerId = workerId;
    final now = _clock();
    final overtime = _workday.isOvertime(now);
    final id = _uuid.v4();
    await _db.sessionDao.insertSession(
      SessionsCompanion.insert(
        localId: id,
        workerId: workerId,
        projectId: project.id,
        taskId: task.id,
        startedAt: now,
        status: 'open',
        kind: Value(overtime ? 'overtime' : 'normal'),
      ),
    );
    await _db.outboxDao.enqueue(
      clientId: id,
      kind: OutboxKind.sessionStart,
      payload: {
        'client_id': id,
        'project_id': project.id,
        'task_id': task.id,
        'started_at': isoUtc(now),
      },
      now: now,
    );
    if (overtime) {
      await _event(AgentEventType.overtimeStart, {'project_id': project.id});
    }
    _warned = false;
    _acc.reset(now);
    state = SessionState(
      status: TrackStatus.active,
      session: WorkSession(
        localId: id,
        projectId: project.id,
        taskId: task.id,
        startedAt: now,
        status: SessionStatus.open,
      ),
      project: project,
      task: task,
      overtime: overtime,
      serverUsedSecs: project.myUsedSeconds,
    );
    await _refreshLive();
    await _refreshBreak(now);
    _startTimer();
    ref.read(syncWorkerProvider).kick();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!ref.read(tickerEnabledProvider)) return;
    _timer = Timer.periodic(Duration(seconds: _pollSecs), (_) => tick());
  }

  // ----------------------------------------------------------------- tick

  /// One poll: sample idle/app, close a heartbeat slice when due, and check
  /// the work-day end. Public so tests can drive time.
  Future<void> tick() async {
    if (_busy || !state.hasSession) return;
    _busy = true;
    try {
      final now = _clock();
      if (state.status == TrackStatus.onBreak) {
        await _refreshBreak(now);
        if (!state.overtime && _workday.isOvertime(now)) {
          await _endBreak(now, resume: false);
          await _stopForWorkdayEnd(now);
        }
        return;
      }
      final slice = _acc.add(_sample(now));
      state = state.copyWith(
        status: _acc.isIdle ? TrackStatus.idle : TrackStatus.active,
      );
      if (slice != null) await _commit(slice);
      await _refreshLive();
      if (!state.overtime && _workday.isOvertime(now)) {
        await _stopForWorkdayEnd(now);
      }
    } finally {
      _busy = false;
    }
  }

  Sample _sample(DateTime now) {
    final fg = ref.read(activeAppMonitorProvider).foreground();
    return Sample(
      at: now,
      idleSecs: ref.read(idleMonitorProvider).idleSecs(),
      app: classifyApp(fg.exe, fg.title),
    );
  }

  /// Takes a last sample and closes whatever is in the current slice.
  Future<void> _flushNow(DateTime now, {bool checkLimits = true}) async {
    final slice = _acc.add(_sample(now));
    if (slice != null) await _commit(slice, checkLimits: checkLimits);
    final tail = _acc.flush(now);
    if (tail != null) await _commit(tail, checkLimits: checkLimits);
  }

  Future<void> _commit(SliceTotals slice, {bool checkLimits = true}) async {
    final s = state.session;
    if (s == null) return;
    await _db.sessionDao.insertHeartbeat(
      HeartbeatsCompanion.insert(
        clientId: _uuid.v4(),
        localSessionId: s.localId,
        fromTime: slice.from,
        toTime: slice.to,
        activeSecs: slice.activeSecs,
        idleSecs: slice.idleSecs,
        appsJson: jsonEncode(slice.apps),
      ),
    );
    await _db.sessionDao.setLastHeartbeat(s.localId, slice.to);
    ref.read(syncWorkerProvider).kick();
    await _refreshLive();
    if (checkLimits && !state.overtime) await _checkLimits();
  }

  Future<void> _checkLimits() async {
    final usage = state.usage;
    final project = state.project;
    if (usage == null || project == null) return;
    if (usage.level == UsageLevel.warning && !_warned) {
      _warned = true;
      state = state.copyWith(
        notice: () => 'You have used 80% of your hours on ${project.code}. '
            '${formatHm(usage.remainingSecs)} left.',
      );
    } else if (usage.level == UsageLevel.over) {
      if (project.overrunMode == OverrunMode.block) {
        await endSession(
          blockMessage: 'Ask your manager for more hours.',
        );
      } else if (!state.overrun) {
        state = state.copyWith(overrun: true);
      }
    }
  }

  // ----------------------------------------------------------------- live

  Future<void> _refreshLive() async {
    final s = state.session;
    final project = state.project;
    if (s == null || project == null) return;
    final now = _clock();
    final day = DateTime(now.year, now.month, now.day);
    final rows = await _db.sessionDao
        .heartbeatsBetween(day, day.add(const Duration(days: 1)));
    final saved = rows.fold<int>(0, (a, r) => a + r.hb.activeSecs);
    final pending = _acc.pendingActiveSecs;
    final unsynced = await _db.sessionDao.unsyncedActiveSecs(project.id);
    state = state.copyWith(
      todayActiveSecs: saved + pending,
      unsyncedSecs: unsynced + (state.overtime ? 0 : pending),
    );
  }

  void _onAck(SyncAck ack) {
    if (ack.projectId != state.project?.id) return;
    state = state.copyWith(serverUsedSecs: ack.usedSecs);
    unawaited(_refreshLive());
  }

  void clearNotice() => state = state.copyWith(notice: () => null);

  void clearBlockMessage() => state = state.copyWith(blockMessage: () => null);

  // ---------------------------------------------------------------- stop

  /// Ends the session cleanly: flushes time, closes the row, queues the stop.
  Future<void> endSession({String? blockMessage}) async {
    final s = state.session;
    if (s == null) return;
    final now = _clock();
    _timer?.cancel();
    if (state.status == TrackStatus.onBreak) {
      await _endBreak(now, resume: false);
    } else {
      await _flushNow(now, checkLimits: false);
    }
    await _closeSession(s.localId, now);
    state = SessionState(blockMessage: blockMessage);
  }

  Future<void> _closeSession(String localId, DateTime now) async {
    await _db.sessionDao.closeSession(localId, endedAt: now, status: 'closed');
    await _db.outboxDao.enqueue(
      clientId: 'stop-$localId',
      kind: OutboxKind.sessionStop,
      payload: {
        'local_id': localId,
        'ended_at': isoUtc(now),
        'unclean': false,
      },
      now: now,
    );
    ref.read(syncWorkerProvider).kick();
  }

  // --------------------------------------------------------------- break

  BreakLedger _ledgerOf(List<BreakRow> rows) => BreakLedger(
        allowanceSecs: _breakAllowance,
        maxPieces: _breakMaxPieces,
        pieces: [for (final r in rows) BreakPiece(r.startedAt, r.endedAt)],
      );

  Future<BreakLedger> ledger() async =>
      _ledgerOf(await _db.breakDao.forDay(_dayFmt.format(_clock())));

  Future<void> _refreshBreak(DateTime now) async {
    final l = await ledger();
    state = state.copyWith(
      breakTakenSecs: l.takenSecs(now),
      breakRemainingSecs: l.remainingSecs(now),
      breakPieces: l.piecesUsed,
    );
  }

  /// Recomputes the break counters (the Break window calls this each second).
  Future<void> refreshBreak() => _refreshBreak(_clock());

  /// Starts a lunch break piece. False if none is available.
  Future<bool> startBreak() async {
    if (!state.hasSession || state.status == TrackStatus.onBreak) return false;
    final now = _clock();
    final l = await ledger();
    if (!l.canStart(now)) return false;
    await _flushNow(now);
    if (!state.hasSession) return false; // hours ran out while flushing
    final piece = l.piecesUsed + 1;
    await _db.breakDao.start(day: _dayFmt.format(now), piece: piece, at: now);
    await _event(AgentEventType.breakStart, {'piece': piece});
    state = state.copyWith(status: TrackStatus.onBreak);
    await _refreshBreak(now);
    return true;
  }

  Future<void> endBreak() async {
    if (state.status != TrackStatus.onBreak) return;
    await _endBreak(_clock(), resume: true);
  }

  Future<void> _endBreak(DateTime now, {required bool resume}) async {
    final open = await _db.breakDao.openBreak();
    if (open != null) {
      await _db.breakDao.end(open.id, now);
      await _event(AgentEventType.breakEnd, {
        'piece': open.piece,
        'secs': now.difference(open.startedAt).inSeconds,
      });
    }
    if (resume) {
      _acc.reset(now);
      state = state.copyWith(status: TrackStatus.active);
    }
    await _refreshBreak(now);
  }

  // ------------------------------------------------------------- workday

  Future<void> _stopForWorkdayEnd(DateTime now) async {
    final s = state.session;
    if (s == null) return;
    _timer?.cancel();
    await _flushNow(now, checkLimits: false);
    await _closeSession(s.localId, now);
    await _event(AgentEventType.workdayEnd, {'project_id': s.projectId});
    state = state.copyWith(
      status: TrackStatus.workdayEnded,
      session: () => null,
    );
  }

  /// "Continue as overtime": a new overtime session on the same task.
  Future<void> continueOvertime() async {
    final project = state.project;
    final task = state.task;
    final worker = _workerId;
    if (state.status != TrackStatus.workdayEnded ||
        project == null ||
        task == null ||
        worker == null) {
      return;
    }
    state = const SessionState();
    await start(workerId: worker, project: project, task: task);
  }

  /// "End work" at the cut-off: the End Work form takes over.
  void declineOvertime() => state = const SessionState();

  Future<void> _event(String type, Map<String, dynamic> data) {
    final now = _clock();
    return _db.outboxDao.enqueue(
      clientId: _uuid.v4(),
      kind: OutboxKind.event,
      payload: {'type': type, 'at': isoUtc(now), 'data': data},
      now: now,
    );
  }
}

final sessionManagerProvider =
    NotifierProvider<SessionManager, SessionState>(SessionManager.new);
