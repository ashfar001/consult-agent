import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [KvEntries])
class KvDao extends DatabaseAccessor<AgentDatabase> with _$KvDaoMixin {
  KvDao(super.db);

  static const deviceIdKey = 'device_id';
  static const authTokenKey = 'auth_token';
  static const workerKey = 'worker';

  Future<String?> get(String key) async {
    final row = await (select(kvEntries)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> put(String key, String value) => into(kvEntries)
      .insertOnConflictUpdate(KvEntriesCompanion.insert(key: key, value: value));

  Future<void> remove(String key) =>
      (delete(kvEntries)..where((t) => t.key.equals(key))).go();

  /// Returns the stored value for [key], creating it with [create] if absent.
  Future<String> getOrCreate(String key, String Function() create) =>
      transaction(() async {
        final existing = await get(key);
        if (existing != null) return existing;
        final value = create();
        await put(key, value);
        return value;
      });
}

@DriftAccessor(tables: [CachedProjects])
class ProjectCacheDao extends DatabaseAccessor<AgentDatabase>
    with _$ProjectCacheDaoMixin {
  ProjectCacheDao(super.db);

  /// Replaces the cache with [projects], preserving their order.
  Future<void> replaceAll(List<Project> projects, DateTime fetchedAt) =>
      transaction(() async {
        await delete(cachedProjects).go();
        await batch((b) {
          b.insertAll(cachedProjects, [
            for (var i = 0; i < projects.length; i++)
              CachedProjectsCompanion.insert(
                id: projects[i].id,
                sortOrder: i,
                json: jsonEncode(projects[i].toJson()),
                fetchedAt: fetchedAt,
              ),
          ]);
        });
      });

  Future<({List<Project> projects, DateTime? fetchedAt})> load() async {
    final rows = await (select(cachedProjects)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return (
      projects: [
        for (final r in rows) Project.fromJson(jsonDecode(r.json) as Json),
      ],
      fetchedAt: rows.isEmpty ? null : rows.first.fetchedAt,
    );
  }

  Future<void> clear() => delete(cachedProjects).go();
}

@DriftAccessor(tables: [Sessions, Heartbeats])
class SessionDao extends DatabaseAccessor<AgentDatabase>
    with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<void> insertSession(SessionsCompanion s) => into(sessions).insert(s);

  Future<SessionRow?> byId(String localId) => (select(sessions)
        ..where((t) => t.localId.equals(localId)))
      .getSingleOrNull();

  Future<SessionRow?> openSession() => (select(sessions)
        ..where((t) => t.status.equals('open'))
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<List<SessionRow>> openSessions() =>
      (select(sessions)..where((t) => t.status.equals('open'))).get();

  Future<void> closeSession(
    String localId, {
    required DateTime endedAt,
    required String status,
  }) =>
      (update(sessions)..where((t) => t.localId.equals(localId))).write(
        SessionsCompanion(endedAt: Value(endedAt), status: Value(status)),
      );

  Future<void> setServerId(String localId, String serverId) =>
      (update(sessions)..where((t) => t.localId.equals(localId)))
          .write(SessionsCompanion(serverId: Value(serverId)));

  Future<void> setLastHeartbeat(String localId, DateTime at) =>
      (update(sessions)..where((t) => t.localId.equals(localId)))
          .write(SessionsCompanion(lastHeartbeatAt: Value(at)));

  Future<void> insertHeartbeat(HeartbeatsCompanion hb) =>
      into(heartbeats).insert(hb, mode: InsertMode.insertOrIgnore);

  /// Unsynced heartbeats, oldest first.
  Future<List<HeartbeatRow>> unsyncedHeartbeats({int limit = 50}) =>
      (select(heartbeats)
            ..where((t) => t.syncedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.fromTime)])
            ..limit(limit))
          .get();

  /// Unsynced heartbeats whose session already has a server id.
  Future<List<({HeartbeatRow hb, SessionRow session})>> sendableHeartbeats({
    int limit = 50,
  }) async {
    final q = select(heartbeats).join([
      innerJoin(sessions, sessions.localId.equalsExp(heartbeats.localSessionId)),
    ])
      ..where(heartbeats.syncedAt.isNull() & sessions.serverId.isNotNull())
      ..orderBy([OrderingTerm.asc(heartbeats.fromTime)])
      ..limit(limit);
    return (await q.get())
        .map((r) => (hb: r.readTable(heartbeats), session: r.readTable(sessions)))
        .toList();
  }

  Future<void> markHeartbeatsSynced(List<String> clientIds, DateTime at) =>
      (update(heartbeats)..where((t) => t.clientId.isIn(clientIds)))
          .write(HeartbeatsCompanion(syncedAt: Value(at)));

  Future<bool> hasUnsyncedHeartbeats(String localSessionId) async {
    final row = await (select(heartbeats)
          ..where((t) =>
              t.localSessionId.equals(localSessionId) & t.syncedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Active seconds recorded locally but not yet acknowledged by the server,
  /// for one project. Overtime never counts against the allocation.
  Future<int> unsyncedActiveSecs(String projectId) async {
    final sum = heartbeats.activeSecs.sum();
    final q = selectOnly(heartbeats).join([
      innerJoin(sessions, sessions.localId.equalsExp(heartbeats.localSessionId)),
    ])
      ..addColumns([sum])
      ..where(heartbeats.syncedAt.isNull() &
          sessions.projectId.equals(projectId) &
          sessions.kind.equals('normal'));
    return (await q.map((r) => r.read(sum)).getSingle()) ?? 0;
  }

  /// Heartbeat rows (with their session) whose slice started in [from, to).
  Future<List<({HeartbeatRow hb, SessionRow session})>> heartbeatsBetween(
    DateTime from,
    DateTime to,
  ) async {
    final q = select(heartbeats).join([
      innerJoin(sessions, sessions.localId.equalsExp(heartbeats.localSessionId)),
    ])
      ..where(heartbeats.fromTime.isBiggerOrEqualValue(from) &
          heartbeats.fromTime.isSmallerThanValue(to))
      ..orderBy([OrderingTerm.asc(heartbeats.fromTime)]);
    return (await q.get())
        .map((r) => (hb: r.readTable(heartbeats), session: r.readTable(sessions)))
        .toList();
  }

  /// Sessions started in [from, to), oldest first.
  Future<List<SessionRow>> sessionsBetween(DateTime from, DateTime to) =>
      (select(sessions)
            ..where((t) =>
                t.startedAt.isBiggerOrEqualValue(from) &
                t.startedAt.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();

  Future<List<SessionRow>> allSessions() => select(sessions).get();
}

@DriftAccessor(tables: [Breaks])
class BreakDao extends DatabaseAccessor<AgentDatabase> with _$BreakDaoMixin {
  BreakDao(super.db);

  Future<int> start({
    required String day,
    required int piece,
    required DateTime at,
  }) =>
      into(breaks).insert(
        BreaksCompanion.insert(day: day, piece: piece, startedAt: at),
      );

  Future<void> end(int id, DateTime at) =>
      (update(breaks)..where((t) => t.id.equals(id)))
          .write(BreaksCompanion(endedAt: Value(at)));

  Future<BreakRow?> openBreak() => (select(breaks)
        ..where((t) => t.endedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<List<BreakRow>> forDay(String day) => (select(breaks)
        ..where((t) => t.day.equals(day))
        ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
      .get();
}

@DriftAccessor(tables: [FileVersions])
class FileDao extends DatabaseAccessor<AgentDatabase> with _$FileDaoMixin {
  FileDao(super.db);

  Future<void> upsert({
    required String projectId,
    required String path,
    required String fileId,
    required int version,
    required DateTime at,
  }) =>
      into(fileVersions).insertOnConflictUpdate(
        FileVersionsCompanion.insert(
          projectId: projectId,
          path: path,
          fileId: fileId,
          version: version,
          syncedAt: at,
        ),
      );

  Future<List<FileVersionRow>> forProject(String projectId) =>
      (select(fileVersions)..where((t) => t.projectId.equals(projectId))).get();
}

@DriftAccessor(tables: [Uploads])
class UploadDao extends DatabaseAccessor<AgentDatabase> with _$UploadDaoMixin {
  UploadDao(super.db);

  Future<void> enqueue(UploadsCompanion u) =>
      into(uploads).insert(u, mode: InsertMode.insertOrIgnore);

  Future<List<UploadRow>> pending() => (select(uploads)
        ..where((t) => t.state.isIn(['queued', 'uploading', 'uploaded']))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<UploadRow?> byClientId(String clientId) => (select(uploads)
        ..where((t) => t.clientId.equals(clientId)))
      .getSingleOrNull();

  Future<void> patch(String clientId, UploadsCompanion c) =>
      (update(uploads)..where((t) => t.clientId.equals(clientId))).write(c);
}

@DriftAccessor(tables: [DailyReports, Sessions])
class ReportDao extends DatabaseAccessor<AgentDatabase> with _$ReportDaoMixin {
  ReportDao(super.db);

  Future<void> save({
    required String date,
    required String workerId,
    required String json,
    required bool submitted,
  }) =>
      into(dailyReports).insertOnConflictUpdate(
        DailyReportsCompanion.insert(
          date: date,
          workerId: workerId,
          json: json,
          submitted: Value(submitted),
        ),
      );

  Future<Set<String>> submittedDates() async {
    final rows = await (select(dailyReports)
          ..where((t) => t.submitted.equals(true)))
        .get();
    return rows.map((r) => r.date).toSet();
  }

  /// Earliest day (yyyy-MM-dd) that still owes a report: a day before [today]
  /// with sessions, or today if one of today's sessions ended unclean.
  Future<String?> pendingDate(String today) async {
    final all = await select(sessions).get();
    final submitted = await submittedDates();
    final fmt = DateFormat('yyyy-MM-dd');
    final owed = <String>{};
    for (final s in all) {
      final d = fmt.format(s.startedAt);
      if (submitted.contains(d)) continue;
      if (d.compareTo(today) < 0 || s.status == 'unclean') owed.add(d);
    }
    if (owed.isEmpty) return null;
    return (owed.toList()..sort()).first;
  }
}

@DriftAccessor(tables: [Outbox])
class OutboxDao extends DatabaseAccessor<AgentDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  /// Queues an idempotent write. Re-enqueueing the same [clientId] is a no-op.
  Future<void> enqueue({
    required String clientId,
    required String kind,
    required Json payload,
    required DateTime now,
  }) =>
      into(outbox).insert(
        OutboxCompanion.insert(
          clientId: clientId,
          kind: kind,
          payloadJson: jsonEncode(payload),
          nextAttemptAt: now,
          createdAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Items due at [now], in FIFO order.
  Future<List<OutboxRow>> due(DateTime now, {int limit = 20}) =>
      (select(outbox)
            ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  Future<void> markDone(int id) =>
      (delete(outbox)..where((t) => t.id.equals(id))).go();

  Future<void> markFailed(int id, String error, DateTime retryAt) =>
      (update(outbox)..where((t) => t.id.equals(id))).write(
        OutboxCompanion.custom(
          attempts: outbox.attempts + const Constant(1),
          lastError: Variable(error),
          nextAttemptAt: Variable(retryAt),
        ),
      );

  Future<int> pendingCount() async {
    final c = outbox.id.count();
    return (await (selectOnly(outbox)..addColumns([c]))
            .map((r) => r.read(c))
            .getSingle()) ??
        0;
  }
}
