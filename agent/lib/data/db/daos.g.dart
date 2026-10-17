// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$KvDaoMixin on DatabaseAccessor<AgentDatabase> {
  $KvEntriesTable get kvEntries => attachedDatabase.kvEntries;
  KvDaoManager get managers => KvDaoManager(this);
}

class KvDaoManager {
  final _$KvDaoMixin _db;
  KvDaoManager(this._db);
  $$KvEntriesTableTableManager get kvEntries =>
      $$KvEntriesTableTableManager(_db.attachedDatabase, _db.kvEntries);
}

mixin _$ProjectCacheDaoMixin on DatabaseAccessor<AgentDatabase> {
  $CachedProjectsTable get cachedProjects => attachedDatabase.cachedProjects;
  ProjectCacheDaoManager get managers => ProjectCacheDaoManager(this);
}

class ProjectCacheDaoManager {
  final _$ProjectCacheDaoMixin _db;
  ProjectCacheDaoManager(this._db);
  $$CachedProjectsTableTableManager get cachedProjects =>
      $$CachedProjectsTableTableManager(
        _db.attachedDatabase,
        _db.cachedProjects,
      );
}

mixin _$SessionDaoMixin on DatabaseAccessor<AgentDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $HeartbeatsTable get heartbeats => attachedDatabase.heartbeats;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$HeartbeatsTableTableManager get heartbeats =>
      $$HeartbeatsTableTableManager(_db.attachedDatabase, _db.heartbeats);
}

mixin _$BreakDaoMixin on DatabaseAccessor<AgentDatabase> {
  $BreaksTable get breaks => attachedDatabase.breaks;
  BreakDaoManager get managers => BreakDaoManager(this);
}

class BreakDaoManager {
  final _$BreakDaoMixin _db;
  BreakDaoManager(this._db);
  $$BreaksTableTableManager get breaks =>
      $$BreaksTableTableManager(_db.attachedDatabase, _db.breaks);
}

mixin _$FileDaoMixin on DatabaseAccessor<AgentDatabase> {
  $FileVersionsTable get fileVersions => attachedDatabase.fileVersions;
  FileDaoManager get managers => FileDaoManager(this);
}

class FileDaoManager {
  final _$FileDaoMixin _db;
  FileDaoManager(this._db);
  $$FileVersionsTableTableManager get fileVersions =>
      $$FileVersionsTableTableManager(_db.attachedDatabase, _db.fileVersions);
}

mixin _$UploadDaoMixin on DatabaseAccessor<AgentDatabase> {
  $UploadsTable get uploads => attachedDatabase.uploads;
  UploadDaoManager get managers => UploadDaoManager(this);
}

class UploadDaoManager {
  final _$UploadDaoMixin _db;
  UploadDaoManager(this._db);
  $$UploadsTableTableManager get uploads =>
      $$UploadsTableTableManager(_db.attachedDatabase, _db.uploads);
}

mixin _$ReportDaoMixin on DatabaseAccessor<AgentDatabase> {
  $DailyReportsTable get dailyReports => attachedDatabase.dailyReports;
  $SessionsTable get sessions => attachedDatabase.sessions;
  ReportDaoManager get managers => ReportDaoManager(this);
}

class ReportDaoManager {
  final _$ReportDaoMixin _db;
  ReportDaoManager(this._db);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db.attachedDatabase, _db.dailyReports);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
}

mixin _$OutboxDaoMixin on DatabaseAccessor<AgentDatabase> {
  $OutboxTable get outbox => attachedDatabase.outbox;
  OutboxDaoManager get managers => OutboxDaoManager(this);
}

class OutboxDaoManager {
  final _$OutboxDaoMixin _db;
  OutboxDaoManager(this._db);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db.attachedDatabase, _db.outbox);
}
