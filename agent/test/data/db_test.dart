import 'package:consult_agent/data/db/database.dart';
import 'package:consult_agent/data/models/models.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Project _p(String id, int used) => Project(
  id: id,
  code: id.toUpperCase(),
  name: 'Project $id',
  client: 'Client',
  overrunMode: OverrunMode.block,
  folderTemplate: const ['01_Survey'],
  myAllocatedHours: 10,
  myUsedSeconds: used,
  projectTotalHours: 20,
  projectUsedSeconds: 100,
  tasks: const [
    ProjectTask(
      id: 't1',
      title: 'Task',
      status: TaskStatus.inProgress,
      allocatedHours: 2,
    ),
  ],
);

void main() {
  late AgentDatabase db;

  setUp(() => db = AgentDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('kv put/get/remove and getOrCreate is stable', () async {
    expect(await db.kvDao.get('a'), isNull);
    await db.kvDao.put('a', '1');
    await db.kvDao.put('a', '2');
    expect(await db.kvDao.get('a'), '2');
    await db.kvDao.remove('a');
    expect(await db.kvDao.get('a'), isNull);

    final id1 = await db.kvDao.getOrCreate('device_id', () => 'x');
    final id2 = await db.kvDao.getOrCreate('device_id', () => 'y');
    expect(id1, 'x');
    expect(id2, 'x');
  });

  test('project cache round-trips and preserves order', () async {
    final t = DateTime(2026, 10, 4, 9, 30);
    await db.projectCacheDao.replaceAll([_p('b', 5), _p('a', 7)], t);
    var cached = await db.projectCacheDao.load();
    expect(cached.projects.map((p) => p.id), ['b', 'a']);
    expect(cached.projects.first.overrunMode, OverrunMode.block);
    expect(cached.projects.first.tasks.single.status, TaskStatus.inProgress);
    expect(cached.fetchedAt, t);

    await db.projectCacheDao.replaceAll([_p('c', 1)], t);
    cached = await db.projectCacheDao.load();
    expect(cached.projects.map((p) => p.id), ['c']);
  });

  test('outbox is FIFO, dedupes client ids and honours backoff', () async {
    final now = DateTime(2026, 10, 4, 10);
    await db.outboxDao.enqueue(
      clientId: 'c1',
      kind: 'event',
      payload: {'n': 1},
      now: now,
    );
    await db.outboxDao.enqueue(
      clientId: 'c2',
      kind: 'event',
      payload: {'n': 2},
      now: now,
    );
    await db.outboxDao.enqueue(
      clientId: 'c1',
      kind: 'event',
      payload: {'n': 99},
      now: now,
    );
    expect(await db.outboxDao.pendingCount(), 2);

    var due = await db.outboxDao.due(now);
    expect(due.map((r) => r.clientId), ['c1', 'c2']);

    await db.outboxDao.markFailed(
      due.first.id,
      'offline',
      now.add(const Duration(minutes: 1)),
    );
    due = await db.outboxDao.due(now);
    expect(due.map((r) => r.clientId), ['c2']);

    final later = await db.outboxDao.due(now.add(const Duration(minutes: 2)));
    expect(later.first.clientId, 'c1');
    expect(later.first.attempts, 1);
    expect(later.first.lastError, 'offline');

    await db.outboxDao.markDone(later.first.id);
    expect(await db.outboxDao.pendingCount(), 1);
  });

  test('unsynced active seconds per project exclude synced rows', () async {
    final t = DateTime(2026, 10, 4, 9);
    await db.sessionDao.insertSession(
      SessionsCompanion.insert(
        localId: 's1',
        workerId: 'w',
        projectId: 'p1',
        taskId: 't',
        startedAt: t,
        status: 'open',
      ),
    );
    Future<void> hb(String id, int active, {DateTime? synced}) =>
        db.sessionDao.insertHeartbeat(
          HeartbeatsCompanion.insert(
            clientId: id,
            localSessionId: 's1',
            fromTime: t,
            toTime: t.add(const Duration(minutes: 1)),
            activeSecs: active,
            idleSecs: 60 - active,
            appsJson: '{}',
            syncedAt: Value(synced),
          ),
        );
    await hb('h1', 40);
    await hb('h2', 50);
    await hb('h3', 60, synced: t);
    await hb('h1', 999); // duplicate client id ignored

    expect(await db.sessionDao.unsyncedActiveSecs('p1'), 90);
    expect(await db.sessionDao.unsyncedActiveSecs('other'), 0);
    expect((await db.sessionDao.openSession())?.localId, 's1');
  });
}
