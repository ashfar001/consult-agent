import 'dart:convert';

import 'package:drift/drift.dart';

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

  Future<SessionRow?> openSession() => (select(sessions)
        ..where((t) => t.status.equals('open'))
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(1))
      .getSingleOrNull();

  Future<void> insertHeartbeat(HeartbeatsCompanion hb) =>
      into(heartbeats).insert(hb, mode: InsertMode.insertOrIgnore);

  /// Unsynced heartbeats, oldest first.
  Future<List<HeartbeatRow>> unsyncedHeartbeats({int limit = 50}) =>
      (select(heartbeats)
            ..where((t) => t.syncedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.fromTime)])
            ..limit(limit))
          .get();

  /// Active seconds recorded locally but not yet acknowledged by the server,
  /// for one project. Added to server `my_used_seconds` in the UI.
  Future<int> unsyncedActiveSecs(String projectId) async {
    final sum = heartbeats.activeSecs.sum();
    final q = selectOnly(heartbeats).join([
      innerJoin(sessions, sessions.localId.equalsExp(heartbeats.localSessionId)),
    ])
      ..addColumns([sum])
      ..where(heartbeats.syncedAt.isNull() &
          sessions.projectId.equals(projectId));
    return (await q.map((r) => r.read(sum)).getSingle()) ?? 0;
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
