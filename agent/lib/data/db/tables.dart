import 'package:drift/drift.dart';

/// Small key/value settings: device_id, encrypted auth token, last worker.
@DataClassName('KvRow')
class KvEntries extends Table {
  @override
  String get tableName => 'kv';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Last successful `my-projects` response, so Project Select works offline.
@DataClassName('CachedProjectRow')
class CachedProjects extends Table {
  TextColumn get id => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local work sessions. `localId` is the client UUID used as `client_id`.
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get workerId => text()();
  TextColumn get projectId => text()();
  TextColumn get taskId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get lastHeartbeatAt => dateTime().nullable()();

  /// open | closed | unclean
  TextColumn get status => text()();

  /// True once sessions/start and (when closed) sessions/stop have synced.
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Time-accounting slices, written before any network call.
@DataClassName('HeartbeatRow')
class Heartbeats extends Table {
  TextColumn get clientId => text()();
  TextColumn get localSessionId => text().references(Sessions, #localId)();
  DateTimeColumn get fromTime => dateTime().named('from_time')();
  DateTimeColumn get toTime => dateTime().named('to_time')();
  IntColumn get activeSecs => integer()();
  IntColumn get idleSecs => integer()();
  TextColumn get appsJson => text()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientId};
}

/// Generic queue of idempotent API writes (session start/stop, events, task
/// complete, daily reports, upload confirms) drained by the SyncWorker.
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get lastError => text().nullable()();
}

/// Which version of each project file is on disk locally.
@DataClassName('FileVersionRow')
class FileVersions extends Table {
  TextColumn get projectId => text()();
  TextColumn get path => text()();
  TextColumn get fileId => text()();
  IntColumn get version => integer()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {projectId, path};
}

/// Pending/resumable uploads.
@DataClassName('UploadRow')
class Uploads extends Table {
  TextColumn get clientId => text()();
  TextColumn get projectId => text()();
  TextColumn get localPath => text()();
  TextColumn get remotePath => text()();
  IntColumn get size => integer()();
  TextColumn get uploadId => text().nullable()();

  /// JSON: part URLs and completed part ETags for multipart resume.
  TextColumn get partsJson => text().withDefault(const Constant('{}'))();

  /// queued | uploading | uploaded | confirmed | failed
  TextColumn get state => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get taskId => text().nullable()();
  BoolColumn get completeTask =>
      boolean().withDefault(const Constant(false))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get resultFileId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {clientId};
}

/// End-of-day reports, kept locally until synced.
@DataClassName('DailyReportRow')
class DailyReports extends Table {
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get workerId => text()();
  TextColumn get json => text()();
  BoolColumn get submitted => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date, workerId};
}
