import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'daos.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    KvEntries,
    CachedProjects,
    Sessions,
    Heartbeats,
    Outbox,
    FileVersions,
    Uploads,
    DailyReports,
    Breaks,
  ],
  daos: [
    KvDao,
    ProjectCacheDao,
    SessionDao,
    OutboxDao,
    BreakDao,
    FileDao,
    UploadDao,
    ReportDao,
  ],
)
class AgentDatabase extends _$AgentDatabase {
  AgentDatabase(super.e);

  /// Opens (creating if needed) `<dataDir>/agent.sqlite`.
  factory AgentDatabase.open(String dataDir) {
    Directory(dataDir).createSync(recursive: true);
    final file = File(p.join(dataDir, 'agent.sqlite'));
    return AgentDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (db) {
          // WAL keeps writes durable and cheap with frequent heartbeat rows.
          db.execute('PRAGMA journal_mode=WAL;');
          db.execute('PRAGMA synchronous=NORMAL;');
          db.execute('PRAGMA foreign_keys=ON;');
        },
      ),
    );
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(sessions, sessions.kind);
            await m.createTable(breaks);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
