import 'package:uuid/uuid.dart';

import '../data/db/database.dart';
import '../data/models/models.dart';
import 'logging.dart';
import 'sync_worker.dart';

/// Cleans up after a crash, power cut or shutdown mid-session.
class RecoveryService {
  RecoveryService({required this.db, required this.clock});

  final AgentDatabase db;
  final DateTime Function() clock;

  /// Closes every session left open at its last heartbeat time, marks it
  /// `unclean`, and queues the stop plus an `unclean_session` event. The next
  /// sign-in then requires the pending report. Returns how many were closed.
  Future<int> recoverUncleanSessions() async {
    final now = clock();
    final open = await db.sessionDao.openSessions();
    for (final s in open) {
      final endedAt = s.lastHeartbeatAt ?? s.startedAt;
      await db.sessionDao
          .closeSession(s.localId, endedAt: endedAt, status: 'unclean');
      await db.outboxDao.enqueue(
        clientId: 'stop-${s.localId}',
        kind: OutboxKind.sessionStop,
        payload: {
          'local_id': s.localId,
          'ended_at': isoUtc(endedAt),
          'unclean': true,
        },
        now: now,
      );
      await db.outboxDao.enqueue(
        clientId: const Uuid().v4(),
        kind: OutboxKind.event,
        payload: {
          'type': AgentEventType.uncleanSession,
          'at': isoUtc(now),
          'data': {
            'session': s.localId,
            'project_id': s.projectId,
            'closed_at': isoUtc(endedAt),
          },
        },
        now: now,
      );
      log.w('Recovered unclean session ${s.localId}, closed at $endedAt');
    }
    // A break left open belongs to a crashed day: end it at its own start.
    final openBreak = await db.breakDao.openBreak();
    if (openBreak != null) {
      await db.breakDao.end(openBreak.id, openBreak.startedAt);
    }
    return open.length;
  }
}
