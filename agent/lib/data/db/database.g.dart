// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $KvEntriesTable extends KvEntries with TableInfo<$KvEntriesTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvEntriesTable createAlias(String alias) {
    return $KvEntriesTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvEntriesCompanion toCompanion(bool nullToAbsent) {
    return KvEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(KvEntriesCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvEntriesCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProjectsTable extends CachedProjects
    with TableInfo<$CachedProjectsTable, CachedProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sortOrder, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedProjectsTable createAlias(String alias) {
    return $CachedProjectsTable(attachedDatabase, alias);
  }
}

class CachedProjectRow extends DataClass
    implements Insertable<CachedProjectRow> {
  final String id;
  final int sortOrder;
  final String json;
  final DateTime fetchedAt;
  const CachedProjectRow({
    required this.id,
    required this.sortOrder,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedProjectsCompanion toCompanion(bool nullToAbsent) {
    return CachedProjectsCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProjectRow(
      id: serializer.fromJson<String>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedProjectRow copyWith({
    String? id,
    int? sortOrder,
    String? json,
    DateTime? fetchedAt,
  }) => CachedProjectRow(
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    json: json ?? this.json,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedProjectRow copyWithCompanion(CachedProjectsCompanion data) {
    return CachedProjectRow(
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProjectRow(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sortOrder, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProjectRow &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class CachedProjectsCompanion extends UpdateCompanion<CachedProjectRow> {
  final Value<String> id;
  final Value<int> sortOrder;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedProjectsCompanion({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProjectsCompanion.insert({
    required String id,
    required int sortOrder,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sortOrder = Value(sortOrder),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedProjectRow> custom({
    Expression<String>? id,
    Expression<int>? sortOrder,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProjectsCompanion copyWith({
    Value<String>? id,
    Value<int>? sortOrder,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedProjectsCompanion(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProjectsCompanion(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastHeartbeatAtMeta = const VerificationMeta(
    'lastHeartbeatAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastHeartbeatAt =
      GeneratedColumn<DateTime>(
        'last_heartbeat_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    workerId,
    projectId,
    taskId,
    startedAt,
    endedAt,
    lastHeartbeatAt,
    status,
    kind,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('last_heartbeat_at')) {
      context.handle(
        _lastHeartbeatAtMeta,
        lastHeartbeatAt.isAcceptableOrUnknown(
          data['last_heartbeat_at']!,
          _lastHeartbeatAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      lastHeartbeatAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_heartbeat_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String localId;
  final String? serverId;
  final String workerId;
  final String projectId;
  final String taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? lastHeartbeatAt;

  /// open | closed | unclean
  final String status;

  /// normal | overtime. Overtime never counts against project allocation.
  final String kind;

  /// True once sessions/start and (when closed) sessions/stop have synced.
  final bool synced;
  const SessionRow({
    required this.localId,
    this.serverId,
    required this.workerId,
    required this.projectId,
    required this.taskId,
    required this.startedAt,
    this.endedAt,
    this.lastHeartbeatAt,
    required this.status,
    required this.kind,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['worker_id'] = Variable<String>(workerId);
    map['project_id'] = Variable<String>(projectId);
    map['task_id'] = Variable<String>(taskId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || lastHeartbeatAt != null) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt);
    }
    map['status'] = Variable<String>(status);
    map['kind'] = Variable<String>(kind);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      workerId: Value(workerId),
      projectId: Value(projectId),
      taskId: Value(taskId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      lastHeartbeatAt: lastHeartbeatAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatAt),
      status: Value(status),
      kind: Value(kind),
      synced: Value(synced),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      workerId: serializer.fromJson<String>(json['workerId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      lastHeartbeatAt: serializer.fromJson<DateTime?>(json['lastHeartbeatAt']),
      status: serializer.fromJson<String>(json['status']),
      kind: serializer.fromJson<String>(json['kind']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'workerId': serializer.toJson<String>(workerId),
      'projectId': serializer.toJson<String>(projectId),
      'taskId': serializer.toJson<String>(taskId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'lastHeartbeatAt': serializer.toJson<DateTime?>(lastHeartbeatAt),
      'status': serializer.toJson<String>(status),
      'kind': serializer.toJson<String>(kind),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  SessionRow copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? workerId,
    String? projectId,
    String? taskId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> lastHeartbeatAt = const Value.absent(),
    String? status,
    String? kind,
    bool? synced,
  }) => SessionRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    workerId: workerId ?? this.workerId,
    projectId: projectId ?? this.projectId,
    taskId: taskId ?? this.taskId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    lastHeartbeatAt: lastHeartbeatAt.present
        ? lastHeartbeatAt.value
        : this.lastHeartbeatAt,
    status: status ?? this.status,
    kind: kind ?? this.kind,
    synced: synced ?? this.synced,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      lastHeartbeatAt: data.lastHeartbeatAt.present
          ? data.lastHeartbeatAt.value
          : this.lastHeartbeatAt,
      status: data.status.present ? data.status.value : this.status,
      kind: data.kind.present ? data.kind.value : this.kind,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('workerId: $workerId, ')
          ..write('projectId: $projectId, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    workerId,
    projectId,
    taskId,
    startedAt,
    endedAt,
    lastHeartbeatAt,
    status,
    kind,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.workerId == this.workerId &&
          other.projectId == this.projectId &&
          other.taskId == this.taskId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.lastHeartbeatAt == this.lastHeartbeatAt &&
          other.status == this.status &&
          other.kind == this.kind &&
          other.synced == this.synced);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> workerId;
  final Value<String> projectId;
  final Value<String> taskId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> lastHeartbeatAt;
  final Value<String> status;
  final Value<String> kind;
  final Value<bool> synced;
  final Value<int> rowid;
  const SessionsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String workerId,
    required String projectId,
    required String taskId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.lastHeartbeatAt = const Value.absent(),
    required String status,
    this.kind = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       workerId = Value(workerId),
       projectId = Value(projectId),
       taskId = Value(taskId),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<SessionRow> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? workerId,
    Expression<String>? projectId,
    Expression<String>? taskId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? lastHeartbeatAt,
    Expression<String>? status,
    Expression<String>? kind,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (workerId != null) 'worker_id': workerId,
      if (projectId != null) 'project_id': projectId,
      if (taskId != null) 'task_id': taskId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (lastHeartbeatAt != null) 'last_heartbeat_at': lastHeartbeatAt,
      if (status != null) 'status': status,
      if (kind != null) 'kind': kind,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? workerId,
    Value<String>? projectId,
    Value<String>? taskId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? lastHeartbeatAt,
    Value<String>? status,
    Value<String>? kind,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      workerId: workerId ?? this.workerId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (lastHeartbeatAt.present) {
      map['last_heartbeat_at'] = Variable<DateTime>(lastHeartbeatAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('workerId: $workerId, ')
          ..write('projectId: $projectId, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('lastHeartbeatAt: $lastHeartbeatAt, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeartbeatsTable extends Heartbeats
    with TableInfo<$HeartbeatsTable, HeartbeatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeartbeatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSessionIdMeta = const VerificationMeta(
    'localSessionId',
  );
  @override
  late final GeneratedColumn<String> localSessionId = GeneratedColumn<String>(
    'local_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (local_id)',
    ),
  );
  static const VerificationMeta _fromTimeMeta = const VerificationMeta(
    'fromTime',
  );
  @override
  late final GeneratedColumn<DateTime> fromTime = GeneratedColumn<DateTime>(
    'from_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toTimeMeta = const VerificationMeta('toTime');
  @override
  late final GeneratedColumn<DateTime> toTime = GeneratedColumn<DateTime>(
    'to_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeSecsMeta = const VerificationMeta(
    'activeSecs',
  );
  @override
  late final GeneratedColumn<int> activeSecs = GeneratedColumn<int>(
    'active_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idleSecsMeta = const VerificationMeta(
    'idleSecs',
  );
  @override
  late final GeneratedColumn<int> idleSecs = GeneratedColumn<int>(
    'idle_secs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appsJsonMeta = const VerificationMeta(
    'appsJson',
  );
  @override
  late final GeneratedColumn<String> appsJson = GeneratedColumn<String>(
    'apps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    localSessionId,
    fromTime,
    toTime,
    activeSecs,
    idleSecs,
    appsJson,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'heartbeats';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeartbeatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('local_session_id')) {
      context.handle(
        _localSessionIdMeta,
        localSessionId.isAcceptableOrUnknown(
          data['local_session_id']!,
          _localSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localSessionIdMeta);
    }
    if (data.containsKey('from_time')) {
      context.handle(
        _fromTimeMeta,
        fromTime.isAcceptableOrUnknown(data['from_time']!, _fromTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_fromTimeMeta);
    }
    if (data.containsKey('to_time')) {
      context.handle(
        _toTimeMeta,
        toTime.isAcceptableOrUnknown(data['to_time']!, _toTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_toTimeMeta);
    }
    if (data.containsKey('active_secs')) {
      context.handle(
        _activeSecsMeta,
        activeSecs.isAcceptableOrUnknown(data['active_secs']!, _activeSecsMeta),
      );
    } else if (isInserting) {
      context.missing(_activeSecsMeta);
    }
    if (data.containsKey('idle_secs')) {
      context.handle(
        _idleSecsMeta,
        idleSecs.isAcceptableOrUnknown(data['idle_secs']!, _idleSecsMeta),
      );
    } else if (isInserting) {
      context.missing(_idleSecsMeta);
    }
    if (data.containsKey('apps_json')) {
      context.handle(
        _appsJsonMeta,
        appsJson.isAcceptableOrUnknown(data['apps_json']!, _appsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_appsJsonMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  HeartbeatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeartbeatRow(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      localSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_session_id'],
      )!,
      fromTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}from_time'],
      )!,
      toTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}to_time'],
      )!,
      activeSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_secs'],
      )!,
      idleSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idle_secs'],
      )!,
      appsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apps_json'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $HeartbeatsTable createAlias(String alias) {
    return $HeartbeatsTable(attachedDatabase, alias);
  }
}

class HeartbeatRow extends DataClass implements Insertable<HeartbeatRow> {
  final String clientId;
  final String localSessionId;
  final DateTime fromTime;
  final DateTime toTime;
  final int activeSecs;
  final int idleSecs;
  final String appsJson;
  final DateTime? syncedAt;
  const HeartbeatRow({
    required this.clientId,
    required this.localSessionId,
    required this.fromTime,
    required this.toTime,
    required this.activeSecs,
    required this.idleSecs,
    required this.appsJson,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['local_session_id'] = Variable<String>(localSessionId);
    map['from_time'] = Variable<DateTime>(fromTime);
    map['to_time'] = Variable<DateTime>(toTime);
    map['active_secs'] = Variable<int>(activeSecs);
    map['idle_secs'] = Variable<int>(idleSecs);
    map['apps_json'] = Variable<String>(appsJson);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  HeartbeatsCompanion toCompanion(bool nullToAbsent) {
    return HeartbeatsCompanion(
      clientId: Value(clientId),
      localSessionId: Value(localSessionId),
      fromTime: Value(fromTime),
      toTime: Value(toTime),
      activeSecs: Value(activeSecs),
      idleSecs: Value(idleSecs),
      appsJson: Value(appsJson),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory HeartbeatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeartbeatRow(
      clientId: serializer.fromJson<String>(json['clientId']),
      localSessionId: serializer.fromJson<String>(json['localSessionId']),
      fromTime: serializer.fromJson<DateTime>(json['fromTime']),
      toTime: serializer.fromJson<DateTime>(json['toTime']),
      activeSecs: serializer.fromJson<int>(json['activeSecs']),
      idleSecs: serializer.fromJson<int>(json['idleSecs']),
      appsJson: serializer.fromJson<String>(json['appsJson']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'localSessionId': serializer.toJson<String>(localSessionId),
      'fromTime': serializer.toJson<DateTime>(fromTime),
      'toTime': serializer.toJson<DateTime>(toTime),
      'activeSecs': serializer.toJson<int>(activeSecs),
      'idleSecs': serializer.toJson<int>(idleSecs),
      'appsJson': serializer.toJson<String>(appsJson),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  HeartbeatRow copyWith({
    String? clientId,
    String? localSessionId,
    DateTime? fromTime,
    DateTime? toTime,
    int? activeSecs,
    int? idleSecs,
    String? appsJson,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => HeartbeatRow(
    clientId: clientId ?? this.clientId,
    localSessionId: localSessionId ?? this.localSessionId,
    fromTime: fromTime ?? this.fromTime,
    toTime: toTime ?? this.toTime,
    activeSecs: activeSecs ?? this.activeSecs,
    idleSecs: idleSecs ?? this.idleSecs,
    appsJson: appsJson ?? this.appsJson,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  HeartbeatRow copyWithCompanion(HeartbeatsCompanion data) {
    return HeartbeatRow(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      localSessionId: data.localSessionId.present
          ? data.localSessionId.value
          : this.localSessionId,
      fromTime: data.fromTime.present ? data.fromTime.value : this.fromTime,
      toTime: data.toTime.present ? data.toTime.value : this.toTime,
      activeSecs: data.activeSecs.present
          ? data.activeSecs.value
          : this.activeSecs,
      idleSecs: data.idleSecs.present ? data.idleSecs.value : this.idleSecs,
      appsJson: data.appsJson.present ? data.appsJson.value : this.appsJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeartbeatRow(')
          ..write('clientId: $clientId, ')
          ..write('localSessionId: $localSessionId, ')
          ..write('fromTime: $fromTime, ')
          ..write('toTime: $toTime, ')
          ..write('activeSecs: $activeSecs, ')
          ..write('idleSecs: $idleSecs, ')
          ..write('appsJson: $appsJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    localSessionId,
    fromTime,
    toTime,
    activeSecs,
    idleSecs,
    appsJson,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeartbeatRow &&
          other.clientId == this.clientId &&
          other.localSessionId == this.localSessionId &&
          other.fromTime == this.fromTime &&
          other.toTime == this.toTime &&
          other.activeSecs == this.activeSecs &&
          other.idleSecs == this.idleSecs &&
          other.appsJson == this.appsJson &&
          other.syncedAt == this.syncedAt);
}

class HeartbeatsCompanion extends UpdateCompanion<HeartbeatRow> {
  final Value<String> clientId;
  final Value<String> localSessionId;
  final Value<DateTime> fromTime;
  final Value<DateTime> toTime;
  final Value<int> activeSecs;
  final Value<int> idleSecs;
  final Value<String> appsJson;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const HeartbeatsCompanion({
    this.clientId = const Value.absent(),
    this.localSessionId = const Value.absent(),
    this.fromTime = const Value.absent(),
    this.toTime = const Value.absent(),
    this.activeSecs = const Value.absent(),
    this.idleSecs = const Value.absent(),
    this.appsJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeartbeatsCompanion.insert({
    required String clientId,
    required String localSessionId,
    required DateTime fromTime,
    required DateTime toTime,
    required int activeSecs,
    required int idleSecs,
    required String appsJson,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       localSessionId = Value(localSessionId),
       fromTime = Value(fromTime),
       toTime = Value(toTime),
       activeSecs = Value(activeSecs),
       idleSecs = Value(idleSecs),
       appsJson = Value(appsJson);
  static Insertable<HeartbeatRow> custom({
    Expression<String>? clientId,
    Expression<String>? localSessionId,
    Expression<DateTime>? fromTime,
    Expression<DateTime>? toTime,
    Expression<int>? activeSecs,
    Expression<int>? idleSecs,
    Expression<String>? appsJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (localSessionId != null) 'local_session_id': localSessionId,
      if (fromTime != null) 'from_time': fromTime,
      if (toTime != null) 'to_time': toTime,
      if (activeSecs != null) 'active_secs': activeSecs,
      if (idleSecs != null) 'idle_secs': idleSecs,
      if (appsJson != null) 'apps_json': appsJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeartbeatsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? localSessionId,
    Value<DateTime>? fromTime,
    Value<DateTime>? toTime,
    Value<int>? activeSecs,
    Value<int>? idleSecs,
    Value<String>? appsJson,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return HeartbeatsCompanion(
      clientId: clientId ?? this.clientId,
      localSessionId: localSessionId ?? this.localSessionId,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      activeSecs: activeSecs ?? this.activeSecs,
      idleSecs: idleSecs ?? this.idleSecs,
      appsJson: appsJson ?? this.appsJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (localSessionId.present) {
      map['local_session_id'] = Variable<String>(localSessionId.value);
    }
    if (fromTime.present) {
      map['from_time'] = Variable<DateTime>(fromTime.value);
    }
    if (toTime.present) {
      map['to_time'] = Variable<DateTime>(toTime.value);
    }
    if (activeSecs.present) {
      map['active_secs'] = Variable<int>(activeSecs.value);
    }
    if (idleSecs.present) {
      map['idle_secs'] = Variable<int>(idleSecs.value);
    }
    if (appsJson.present) {
      map['apps_json'] = Variable<String>(appsJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeartbeatsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('localSessionId: $localSessionId, ')
          ..write('fromTime: $fromTime, ')
          ..write('toTime: $toTime, ')
          ..write('activeSecs: $activeSecs, ')
          ..write('idleSecs: $idleSecs, ')
          ..write('appsJson: $appsJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    kind,
    payloadJson,
    attempts,
    nextAttemptAt,
    createdAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;
  final String clientId;
  final String kind;
  final String payloadJson;
  final int attempts;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final String? lastError;
  const OutboxRow({
    required this.id,
    required this.clientId,
    required this.kind,
    required this.payloadJson,
    required this.attempts,
    required this.nextAttemptAt,
    required this.createdAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_id'] = Variable<String>(clientId);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      clientId: Value(clientId),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      createdAt: Value(createdAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String>(clientId),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? clientId,
    String? kind,
    String? payloadJson,
    int? attempts,
    DateTime? nextAttemptAt,
    DateTime? createdAt,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxRow(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    createdAt: createdAt ?? this.createdAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    kind,
    payloadJson,
    attempts,
    nextAttemptAt,
    createdAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.createdAt == this.createdAt &&
          other.lastError == this.lastError);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> clientId;
  final Value<String> kind;
  final Value<String> payloadJson;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime> createdAt;
  final Value<String?> lastError;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String clientId,
    required String kind,
    required String payloadJson,
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    required DateTime createdAt,
    this.lastError = const Value.absent(),
  }) : clientId = Value(clientId),
       kind = Value(kind),
       payloadJson = Value(payloadJson),
       nextAttemptAt = Value(nextAttemptAt),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<String>? kind,
    Expression<String>? payloadJson,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? createdAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? clientId,
    Value<String>? kind,
    Value<String>? payloadJson,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime>? createdAt,
    Value<String?>? lastError,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      createdAt: createdAt ?? this.createdAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $FileVersionsTable extends FileVersions
    with TableInfo<$FileVersionsTable, FileVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectId,
    path,
    fileId,
    version,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {projectId, path};
  @override
  FileVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileVersionRow(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $FileVersionsTable createAlias(String alias) {
    return $FileVersionsTable(attachedDatabase, alias);
  }
}

class FileVersionRow extends DataClass implements Insertable<FileVersionRow> {
  final String projectId;
  final String path;
  final String fileId;
  final int version;
  final DateTime syncedAt;
  const FileVersionRow({
    required this.projectId,
    required this.path,
    required this.fileId,
    required this.version,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['path'] = Variable<String>(path);
    map['file_id'] = Variable<String>(fileId);
    map['version'] = Variable<int>(version);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  FileVersionsCompanion toCompanion(bool nullToAbsent) {
    return FileVersionsCompanion(
      projectId: Value(projectId),
      path: Value(path),
      fileId: Value(fileId),
      version: Value(version),
      syncedAt: Value(syncedAt),
    );
  }

  factory FileVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileVersionRow(
      projectId: serializer.fromJson<String>(json['projectId']),
      path: serializer.fromJson<String>(json['path']),
      fileId: serializer.fromJson<String>(json['fileId']),
      version: serializer.fromJson<int>(json['version']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<String>(projectId),
      'path': serializer.toJson<String>(path),
      'fileId': serializer.toJson<String>(fileId),
      'version': serializer.toJson<int>(version),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  FileVersionRow copyWith({
    String? projectId,
    String? path,
    String? fileId,
    int? version,
    DateTime? syncedAt,
  }) => FileVersionRow(
    projectId: projectId ?? this.projectId,
    path: path ?? this.path,
    fileId: fileId ?? this.fileId,
    version: version ?? this.version,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  FileVersionRow copyWithCompanion(FileVersionsCompanion data) {
    return FileVersionRow(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      path: data.path.present ? data.path.value : this.path,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      version: data.version.present ? data.version.value : this.version,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileVersionRow(')
          ..write('projectId: $projectId, ')
          ..write('path: $path, ')
          ..write('fileId: $fileId, ')
          ..write('version: $version, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(projectId, path, fileId, version, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileVersionRow &&
          other.projectId == this.projectId &&
          other.path == this.path &&
          other.fileId == this.fileId &&
          other.version == this.version &&
          other.syncedAt == this.syncedAt);
}

class FileVersionsCompanion extends UpdateCompanion<FileVersionRow> {
  final Value<String> projectId;
  final Value<String> path;
  final Value<String> fileId;
  final Value<int> version;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const FileVersionsCompanion({
    this.projectId = const Value.absent(),
    this.path = const Value.absent(),
    this.fileId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileVersionsCompanion.insert({
    required String projectId,
    required String path,
    required String fileId,
    required int version,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       path = Value(path),
       fileId = Value(fileId),
       version = Value(version),
       syncedAt = Value(syncedAt);
  static Insertable<FileVersionRow> custom({
    Expression<String>? projectId,
    Expression<String>? path,
    Expression<String>? fileId,
    Expression<int>? version,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (path != null) 'path': path,
      if (fileId != null) 'file_id': fileId,
      if (version != null) 'version': version,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileVersionsCompanion copyWith({
    Value<String>? projectId,
    Value<String>? path,
    Value<String>? fileId,
    Value<int>? version,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return FileVersionsCompanion(
      projectId: projectId ?? this.projectId,
      path: path ?? this.path,
      fileId: fileId ?? this.fileId,
      version: version ?? this.version,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileVersionsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('path: $path, ')
          ..write('fileId: $fileId, ')
          ..write('version: $version, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadsTable extends Uploads with TableInfo<$UploadsTable, UploadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadIdMeta = const VerificationMeta(
    'uploadId',
  );
  @override
  late final GeneratedColumn<String> uploadId = GeneratedColumn<String>(
    'upload_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partsJsonMeta = const VerificationMeta(
    'partsJson',
  );
  @override
  late final GeneratedColumn<String> partsJson = GeneratedColumn<String>(
    'parts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completeTaskMeta = const VerificationMeta(
    'completeTask',
  );
  @override
  late final GeneratedColumn<bool> completeTask = GeneratedColumn<bool>(
    'complete_task',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete_task" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resultFileIdMeta = const VerificationMeta(
    'resultFileId',
  );
  @override
  late final GeneratedColumn<String> resultFileId = GeneratedColumn<String>(
    'result_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    projectId,
    localPath,
    remotePath,
    size,
    uploadId,
    partsJson,
    state,
    note,
    taskId,
    completeTask,
    attempts,
    resultFileId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('upload_id')) {
      context.handle(
        _uploadIdMeta,
        uploadId.isAcceptableOrUnknown(data['upload_id']!, _uploadIdMeta),
      );
    }
    if (data.containsKey('parts_json')) {
      context.handle(
        _partsJsonMeta,
        partsJson.isAcceptableOrUnknown(data['parts_json']!, _partsJsonMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('complete_task')) {
      context.handle(
        _completeTaskMeta,
        completeTask.isAcceptableOrUnknown(
          data['complete_task']!,
          _completeTaskMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('result_file_id')) {
      context.handle(
        _resultFileIdMeta,
        resultFileId.isAcceptableOrUnknown(
          data['result_file_id']!,
          _resultFileIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  UploadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadRow(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      uploadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_id'],
      ),
      partsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parts_json'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      completeTask: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete_task'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      resultFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_file_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UploadsTable createAlias(String alias) {
    return $UploadsTable(attachedDatabase, alias);
  }
}

class UploadRow extends DataClass implements Insertable<UploadRow> {
  final String clientId;
  final String projectId;
  final String localPath;
  final String remotePath;
  final int size;
  final String? uploadId;

  /// JSON: part URLs and completed part ETags for multipart resume.
  final String partsJson;

  /// queued | uploading | uploaded | confirmed | failed
  final String state;
  final String note;
  final String? taskId;
  final bool completeTask;
  final int attempts;
  final String? resultFileId;
  final DateTime createdAt;
  const UploadRow({
    required this.clientId,
    required this.projectId,
    required this.localPath,
    required this.remotePath,
    required this.size,
    this.uploadId,
    required this.partsJson,
    required this.state,
    required this.note,
    this.taskId,
    required this.completeTask,
    required this.attempts,
    this.resultFileId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['project_id'] = Variable<String>(projectId);
    map['local_path'] = Variable<String>(localPath);
    map['remote_path'] = Variable<String>(remotePath);
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || uploadId != null) {
      map['upload_id'] = Variable<String>(uploadId);
    }
    map['parts_json'] = Variable<String>(partsJson);
    map['state'] = Variable<String>(state);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['complete_task'] = Variable<bool>(completeTask);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || resultFileId != null) {
      map['result_file_id'] = Variable<String>(resultFileId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UploadsCompanion toCompanion(bool nullToAbsent) {
    return UploadsCompanion(
      clientId: Value(clientId),
      projectId: Value(projectId),
      localPath: Value(localPath),
      remotePath: Value(remotePath),
      size: Value(size),
      uploadId: uploadId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadId),
      partsJson: Value(partsJson),
      state: Value(state),
      note: Value(note),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      completeTask: Value(completeTask),
      attempts: Value(attempts),
      resultFileId: resultFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(resultFileId),
      createdAt: Value(createdAt),
    );
  }

  factory UploadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadRow(
      clientId: serializer.fromJson<String>(json['clientId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      size: serializer.fromJson<int>(json['size']),
      uploadId: serializer.fromJson<String?>(json['uploadId']),
      partsJson: serializer.fromJson<String>(json['partsJson']),
      state: serializer.fromJson<String>(json['state']),
      note: serializer.fromJson<String>(json['note']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      completeTask: serializer.fromJson<bool>(json['completeTask']),
      attempts: serializer.fromJson<int>(json['attempts']),
      resultFileId: serializer.fromJson<String?>(json['resultFileId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'projectId': serializer.toJson<String>(projectId),
      'localPath': serializer.toJson<String>(localPath),
      'remotePath': serializer.toJson<String>(remotePath),
      'size': serializer.toJson<int>(size),
      'uploadId': serializer.toJson<String?>(uploadId),
      'partsJson': serializer.toJson<String>(partsJson),
      'state': serializer.toJson<String>(state),
      'note': serializer.toJson<String>(note),
      'taskId': serializer.toJson<String?>(taskId),
      'completeTask': serializer.toJson<bool>(completeTask),
      'attempts': serializer.toJson<int>(attempts),
      'resultFileId': serializer.toJson<String?>(resultFileId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UploadRow copyWith({
    String? clientId,
    String? projectId,
    String? localPath,
    String? remotePath,
    int? size,
    Value<String?> uploadId = const Value.absent(),
    String? partsJson,
    String? state,
    String? note,
    Value<String?> taskId = const Value.absent(),
    bool? completeTask,
    int? attempts,
    Value<String?> resultFileId = const Value.absent(),
    DateTime? createdAt,
  }) => UploadRow(
    clientId: clientId ?? this.clientId,
    projectId: projectId ?? this.projectId,
    localPath: localPath ?? this.localPath,
    remotePath: remotePath ?? this.remotePath,
    size: size ?? this.size,
    uploadId: uploadId.present ? uploadId.value : this.uploadId,
    partsJson: partsJson ?? this.partsJson,
    state: state ?? this.state,
    note: note ?? this.note,
    taskId: taskId.present ? taskId.value : this.taskId,
    completeTask: completeTask ?? this.completeTask,
    attempts: attempts ?? this.attempts,
    resultFileId: resultFileId.present ? resultFileId.value : this.resultFileId,
    createdAt: createdAt ?? this.createdAt,
  );
  UploadRow copyWithCompanion(UploadsCompanion data) {
    return UploadRow(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      size: data.size.present ? data.size.value : this.size,
      uploadId: data.uploadId.present ? data.uploadId.value : this.uploadId,
      partsJson: data.partsJson.present ? data.partsJson.value : this.partsJson,
      state: data.state.present ? data.state.value : this.state,
      note: data.note.present ? data.note.value : this.note,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      completeTask: data.completeTask.present
          ? data.completeTask.value
          : this.completeTask,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      resultFileId: data.resultFileId.present
          ? data.resultFileId.value
          : this.resultFileId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadRow(')
          ..write('clientId: $clientId, ')
          ..write('projectId: $projectId, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('size: $size, ')
          ..write('uploadId: $uploadId, ')
          ..write('partsJson: $partsJson, ')
          ..write('state: $state, ')
          ..write('note: $note, ')
          ..write('taskId: $taskId, ')
          ..write('completeTask: $completeTask, ')
          ..write('attempts: $attempts, ')
          ..write('resultFileId: $resultFileId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    projectId,
    localPath,
    remotePath,
    size,
    uploadId,
    partsJson,
    state,
    note,
    taskId,
    completeTask,
    attempts,
    resultFileId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadRow &&
          other.clientId == this.clientId &&
          other.projectId == this.projectId &&
          other.localPath == this.localPath &&
          other.remotePath == this.remotePath &&
          other.size == this.size &&
          other.uploadId == this.uploadId &&
          other.partsJson == this.partsJson &&
          other.state == this.state &&
          other.note == this.note &&
          other.taskId == this.taskId &&
          other.completeTask == this.completeTask &&
          other.attempts == this.attempts &&
          other.resultFileId == this.resultFileId &&
          other.createdAt == this.createdAt);
}

class UploadsCompanion extends UpdateCompanion<UploadRow> {
  final Value<String> clientId;
  final Value<String> projectId;
  final Value<String> localPath;
  final Value<String> remotePath;
  final Value<int> size;
  final Value<String?> uploadId;
  final Value<String> partsJson;
  final Value<String> state;
  final Value<String> note;
  final Value<String?> taskId;
  final Value<bool> completeTask;
  final Value<int> attempts;
  final Value<String?> resultFileId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UploadsCompanion({
    this.clientId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.size = const Value.absent(),
    this.uploadId = const Value.absent(),
    this.partsJson = const Value.absent(),
    this.state = const Value.absent(),
    this.note = const Value.absent(),
    this.taskId = const Value.absent(),
    this.completeTask = const Value.absent(),
    this.attempts = const Value.absent(),
    this.resultFileId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadsCompanion.insert({
    required String clientId,
    required String projectId,
    required String localPath,
    required String remotePath,
    required int size,
    this.uploadId = const Value.absent(),
    this.partsJson = const Value.absent(),
    required String state,
    this.note = const Value.absent(),
    this.taskId = const Value.absent(),
    this.completeTask = const Value.absent(),
    this.attempts = const Value.absent(),
    this.resultFileId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       projectId = Value(projectId),
       localPath = Value(localPath),
       remotePath = Value(remotePath),
       size = Value(size),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<UploadRow> custom({
    Expression<String>? clientId,
    Expression<String>? projectId,
    Expression<String>? localPath,
    Expression<String>? remotePath,
    Expression<int>? size,
    Expression<String>? uploadId,
    Expression<String>? partsJson,
    Expression<String>? state,
    Expression<String>? note,
    Expression<String>? taskId,
    Expression<bool>? completeTask,
    Expression<int>? attempts,
    Expression<String>? resultFileId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (projectId != null) 'project_id': projectId,
      if (localPath != null) 'local_path': localPath,
      if (remotePath != null) 'remote_path': remotePath,
      if (size != null) 'size': size,
      if (uploadId != null) 'upload_id': uploadId,
      if (partsJson != null) 'parts_json': partsJson,
      if (state != null) 'state': state,
      if (note != null) 'note': note,
      if (taskId != null) 'task_id': taskId,
      if (completeTask != null) 'complete_task': completeTask,
      if (attempts != null) 'attempts': attempts,
      if (resultFileId != null) 'result_file_id': resultFileId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? projectId,
    Value<String>? localPath,
    Value<String>? remotePath,
    Value<int>? size,
    Value<String?>? uploadId,
    Value<String>? partsJson,
    Value<String>? state,
    Value<String>? note,
    Value<String?>? taskId,
    Value<bool>? completeTask,
    Value<int>? attempts,
    Value<String?>? resultFileId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UploadsCompanion(
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      size: size ?? this.size,
      uploadId: uploadId ?? this.uploadId,
      partsJson: partsJson ?? this.partsJson,
      state: state ?? this.state,
      note: note ?? this.note,
      taskId: taskId ?? this.taskId,
      completeTask: completeTask ?? this.completeTask,
      attempts: attempts ?? this.attempts,
      resultFileId: resultFileId ?? this.resultFileId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (uploadId.present) {
      map['upload_id'] = Variable<String>(uploadId.value);
    }
    if (partsJson.present) {
      map['parts_json'] = Variable<String>(partsJson.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (completeTask.present) {
      map['complete_task'] = Variable<bool>(completeTask.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (resultFileId.present) {
      map['result_file_id'] = Variable<String>(resultFileId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('projectId: $projectId, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('size: $size, ')
          ..write('uploadId: $uploadId, ')
          ..write('partsJson: $partsJson, ')
          ..write('state: $state, ')
          ..write('note: $note, ')
          ..write('taskId: $taskId, ')
          ..write('completeTask: $completeTask, ')
          ..write('attempts: $attempts, ')
          ..write('resultFileId: $resultFileId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReportsTable extends DailyReports
    with TableInfo<$DailyReportsTable, DailyReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submittedMeta = const VerificationMeta(
    'submitted',
  );
  @override
  late final GeneratedColumn<bool> submitted = GeneratedColumn<bool>(
    'submitted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("submitted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    workerId,
    json,
    submitted,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('submitted')) {
      context.handle(
        _submittedMeta,
        submitted.isAcceptableOrUnknown(data['submitted']!, _submittedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, workerId};
  @override
  DailyReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReportRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      submitted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}submitted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $DailyReportsTable createAlias(String alias) {
    return $DailyReportsTable(attachedDatabase, alias);
  }
}

class DailyReportRow extends DataClass implements Insertable<DailyReportRow> {
  final String date;
  final String workerId;
  final String json;
  final bool submitted;
  final bool synced;
  const DailyReportRow({
    required this.date,
    required this.workerId,
    required this.json,
    required this.submitted,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['worker_id'] = Variable<String>(workerId);
    map['json'] = Variable<String>(json);
    map['submitted'] = Variable<bool>(submitted);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  DailyReportsCompanion toCompanion(bool nullToAbsent) {
    return DailyReportsCompanion(
      date: Value(date),
      workerId: Value(workerId),
      json: Value(json),
      submitted: Value(submitted),
      synced: Value(synced),
    );
  }

  factory DailyReportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReportRow(
      date: serializer.fromJson<String>(json['date']),
      workerId: serializer.fromJson<String>(json['workerId']),
      json: serializer.fromJson<String>(json['json']),
      submitted: serializer.fromJson<bool>(json['submitted']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'workerId': serializer.toJson<String>(workerId),
      'json': serializer.toJson<String>(json),
      'submitted': serializer.toJson<bool>(submitted),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  DailyReportRow copyWith({
    String? date,
    String? workerId,
    String? json,
    bool? submitted,
    bool? synced,
  }) => DailyReportRow(
    date: date ?? this.date,
    workerId: workerId ?? this.workerId,
    json: json ?? this.json,
    submitted: submitted ?? this.submitted,
    synced: synced ?? this.synced,
  );
  DailyReportRow copyWithCompanion(DailyReportsCompanion data) {
    return DailyReportRow(
      date: data.date.present ? data.date.value : this.date,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      json: data.json.present ? data.json.value : this.json,
      submitted: data.submitted.present ? data.submitted.value : this.submitted,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportRow(')
          ..write('date: $date, ')
          ..write('workerId: $workerId, ')
          ..write('json: $json, ')
          ..write('submitted: $submitted, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, workerId, json, submitted, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReportRow &&
          other.date == this.date &&
          other.workerId == this.workerId &&
          other.json == this.json &&
          other.submitted == this.submitted &&
          other.synced == this.synced);
}

class DailyReportsCompanion extends UpdateCompanion<DailyReportRow> {
  final Value<String> date;
  final Value<String> workerId;
  final Value<String> json;
  final Value<bool> submitted;
  final Value<bool> synced;
  final Value<int> rowid;
  const DailyReportsCompanion({
    this.date = const Value.absent(),
    this.workerId = const Value.absent(),
    this.json = const Value.absent(),
    this.submitted = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReportsCompanion.insert({
    required String date,
    required String workerId,
    required String json,
    this.submitted = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       workerId = Value(workerId),
       json = Value(json);
  static Insertable<DailyReportRow> custom({
    Expression<String>? date,
    Expression<String>? workerId,
    Expression<String>? json,
    Expression<bool>? submitted,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (workerId != null) 'worker_id': workerId,
      if (json != null) 'json': json,
      if (submitted != null) 'submitted': submitted,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReportsCompanion copyWith({
    Value<String>? date,
    Value<String>? workerId,
    Value<String>? json,
    Value<bool>? submitted,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return DailyReportsCompanion(
      date: date ?? this.date,
      workerId: workerId ?? this.workerId,
      json: json ?? this.json,
      submitted: submitted ?? this.submitted,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (submitted.present) {
      map['submitted'] = Variable<bool>(submitted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsCompanion(')
          ..write('date: $date, ')
          ..write('workerId: $workerId, ')
          ..write('json: $json, ')
          ..write('submitted: $submitted, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BreaksTable extends Breaks with TableInfo<$BreaksTable, BreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pieceMeta = const VerificationMeta('piece');
  @override
  late final GeneratedColumn<int> piece = GeneratedColumn<int>(
    'piece',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, piece, startedAt, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'breaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreakRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('piece')) {
      context.handle(
        _pieceMeta,
        piece.isAcceptableOrUnknown(data['piece']!, _pieceMeta),
      );
    } else if (isInserting) {
      context.missing(_pieceMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreakRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      piece: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}piece'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $BreaksTable createAlias(String alias) {
    return $BreaksTable(attachedDatabase, alias);
  }
}

class BreakRow extends DataClass implements Insertable<BreakRow> {
  final int id;
  final String day;
  final int piece;
  final DateTime startedAt;
  final DateTime? endedAt;
  const BreakRow({
    required this.id,
    required this.day,
    required this.piece,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    map['piece'] = Variable<int>(piece);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  BreaksCompanion toCompanion(bool nullToAbsent) {
    return BreaksCompanion(
      id: Value(id),
      day: Value(day),
      piece: Value(piece),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory BreakRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreakRow(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      piece: serializer.fromJson<int>(json['piece']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'piece': serializer.toJson<int>(piece),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  BreakRow copyWith({
    int? id,
    String? day,
    int? piece,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => BreakRow(
    id: id ?? this.id,
    day: day ?? this.day,
    piece: piece ?? this.piece,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  BreakRow copyWithCompanion(BreaksCompanion data) {
    return BreakRow(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      piece: data.piece.present ? data.piece.value : this.piece,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreakRow(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('piece: $piece, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, piece, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreakRow &&
          other.id == this.id &&
          other.day == this.day &&
          other.piece == this.piece &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class BreaksCompanion extends UpdateCompanion<BreakRow> {
  final Value<int> id;
  final Value<String> day;
  final Value<int> piece;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  const BreaksCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.piece = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  BreaksCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    required int piece,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
  }) : day = Value(day),
       piece = Value(piece),
       startedAt = Value(startedAt);
  static Insertable<BreakRow> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<int>? piece,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (piece != null) 'piece': piece,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  BreaksCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<int>? piece,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
  }) {
    return BreaksCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      piece: piece ?? this.piece,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (piece.present) {
      map['piece'] = Variable<int>(piece.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreaksCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('piece: $piece, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AgentDatabase extends GeneratedDatabase {
  _$AgentDatabase(QueryExecutor e) : super(e);
  $AgentDatabaseManager get managers => $AgentDatabaseManager(this);
  late final $KvEntriesTable kvEntries = $KvEntriesTable(this);
  late final $CachedProjectsTable cachedProjects = $CachedProjectsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $HeartbeatsTable heartbeats = $HeartbeatsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $FileVersionsTable fileVersions = $FileVersionsTable(this);
  late final $UploadsTable uploads = $UploadsTable(this);
  late final $DailyReportsTable dailyReports = $DailyReportsTable(this);
  late final $BreaksTable breaks = $BreaksTable(this);
  late final KvDao kvDao = KvDao(this as AgentDatabase);
  late final ProjectCacheDao projectCacheDao = ProjectCacheDao(
    this as AgentDatabase,
  );
  late final SessionDao sessionDao = SessionDao(this as AgentDatabase);
  late final OutboxDao outboxDao = OutboxDao(this as AgentDatabase);
  late final BreakDao breakDao = BreakDao(this as AgentDatabase);
  late final FileDao fileDao = FileDao(this as AgentDatabase);
  late final UploadDao uploadDao = UploadDao(this as AgentDatabase);
  late final ReportDao reportDao = ReportDao(this as AgentDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kvEntries,
    cachedProjects,
    sessions,
    heartbeats,
    outbox,
    fileVersions,
    uploads,
    dailyReports,
    breaks,
  ];
}

typedef $$KvEntriesTableCreateCompanionBuilder =
    KvEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KvEntriesTableUpdateCompanionBuilder =
    KvEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KvEntriesTableFilterComposer
    extends Composer<_$AgentDatabase, $KvEntriesTable> {
  $$KvEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvEntriesTableOrderingComposer
    extends Composer<_$AgentDatabase, $KvEntriesTable> {
  $$KvEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvEntriesTableAnnotationComposer
    extends Composer<_$AgentDatabase, $KvEntriesTable> {
  $$KvEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvEntriesTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $KvEntriesTable,
          KvRow,
          $$KvEntriesTableFilterComposer,
          $$KvEntriesTableOrderingComposer,
          $$KvEntriesTableAnnotationComposer,
          $$KvEntriesTableCreateCompanionBuilder,
          $$KvEntriesTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AgentDatabase, $KvEntriesTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$KvEntriesTableTableManager(_$AgentDatabase db, $KvEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $KvEntriesTable,
      KvRow,
      $$KvEntriesTableFilterComposer,
      $$KvEntriesTableOrderingComposer,
      $$KvEntriesTableAnnotationComposer,
      $$KvEntriesTableCreateCompanionBuilder,
      $$KvEntriesTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AgentDatabase, $KvEntriesTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;
typedef $$CachedProjectsTableCreateCompanionBuilder =
    CachedProjectsCompanion Function({
      required String id,
      required int sortOrder,
      required String json,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedProjectsTableUpdateCompanionBuilder =
    CachedProjectsCompanion Function({
      Value<String> id,
      Value<int> sortOrder,
      Value<String> json,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedProjectsTableFilterComposer
    extends Composer<_$AgentDatabase, $CachedProjectsTable> {
  $$CachedProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProjectsTableOrderingComposer
    extends Composer<_$AgentDatabase, $CachedProjectsTable> {
  $$CachedProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProjectsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $CachedProjectsTable> {
  $$CachedProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedProjectsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $CachedProjectsTable,
          CachedProjectRow,
          $$CachedProjectsTableFilterComposer,
          $$CachedProjectsTableOrderingComposer,
          $$CachedProjectsTableAnnotationComposer,
          $$CachedProjectsTableCreateCompanionBuilder,
          $$CachedProjectsTableUpdateCompanionBuilder,
          (
            CachedProjectRow,
            BaseReferences<
              _$AgentDatabase,
              $CachedProjectsTable,
              CachedProjectRow
            >,
          ),
          CachedProjectRow,
          PrefetchHooks Function()
        > {
  $$CachedProjectsTableTableManager(
    _$AgentDatabase db,
    $CachedProjectsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProjectsCompanion(
                id: id,
                sortOrder: sortOrder,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int sortOrder,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProjectsCompanion.insert(
                id: id,
                sortOrder: sortOrder,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $CachedProjectsTable,
      CachedProjectRow,
      $$CachedProjectsTableFilterComposer,
      $$CachedProjectsTableOrderingComposer,
      $$CachedProjectsTableAnnotationComposer,
      $$CachedProjectsTableCreateCompanionBuilder,
      $$CachedProjectsTableUpdateCompanionBuilder,
      (
        CachedProjectRow,
        BaseReferences<_$AgentDatabase, $CachedProjectsTable, CachedProjectRow>,
      ),
      CachedProjectRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String localId,
      Value<String?> serverId,
      required String workerId,
      required String projectId,
      required String taskId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> lastHeartbeatAt,
      required String status,
      Value<String> kind,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String> workerId,
      Value<String> projectId,
      Value<String> taskId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<DateTime?> lastHeartbeatAt,
      Value<String> status,
      Value<String> kind,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AgentDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HeartbeatsTable, List<HeartbeatRow>>
  _heartbeatsRefsTable(_$AgentDatabase db) => MultiTypedResultKey.fromTable(
    db.heartbeats,
    aliasName: 'sessions__local_id__heartbeats__local_session_id',
  );

  $$HeartbeatsTableProcessedTableManager get heartbeatsRefs {
    final manager = $$HeartbeatsTableTableManager($_db, $_db.heartbeats).filter(
      (f) =>
          f.localSessionId.localId.sqlEquals($_itemColumn<String>('local_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_heartbeatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> heartbeatsRefs(
    Expression<bool> Function($$HeartbeatsTableFilterComposer f) f,
  ) {
    final $$HeartbeatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.heartbeats,
      getReferencedColumn: (t) => t.localSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartbeatsTableFilterComposer(
            $db: $db,
            $table: $db.heartbeats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastHeartbeatAt => $composableBuilder(
    column: $table.lastHeartbeatAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  Expression<T> heartbeatsRefs<T extends Object>(
    Expression<T> Function($$HeartbeatsTableAnnotationComposer a) f,
  ) {
    final $$HeartbeatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.heartbeats,
      getReferencedColumn: (t) => t.localSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HeartbeatsTableAnnotationComposer(
            $db: $db,
            $table: $db.heartbeats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool heartbeatsRefs})
        > {
  $$SessionsTableTableManager(_$AgentDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> workerId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                localId: localId,
                serverId: serverId,
                workerId: workerId,
                projectId: projectId,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                lastHeartbeatAt: lastHeartbeatAt,
                status: status,
                kind: kind,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String workerId,
                required String projectId,
                required String taskId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> lastHeartbeatAt = const Value.absent(),
                required String status,
                Value<String> kind = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                localId: localId,
                serverId: serverId,
                workerId: workerId,
                projectId: projectId,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                lastHeartbeatAt: lastHeartbeatAt,
                status: status,
                kind: kind,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({heartbeatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (heartbeatsRefs) db.heartbeats],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (heartbeatsRefs)
                    await $_getPrefetchedData<
                      SessionRow,
                      $SessionsTable,
                      HeartbeatRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._heartbeatsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).heartbeatsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.localSessionId == item.localId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool heartbeatsRefs})
    >;
typedef $$HeartbeatsTableCreateCompanionBuilder =
    HeartbeatsCompanion Function({
      required String clientId,
      required String localSessionId,
      required DateTime fromTime,
      required DateTime toTime,
      required int activeSecs,
      required int idleSecs,
      required String appsJson,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$HeartbeatsTableUpdateCompanionBuilder =
    HeartbeatsCompanion Function({
      Value<String> clientId,
      Value<String> localSessionId,
      Value<DateTime> fromTime,
      Value<DateTime> toTime,
      Value<int> activeSecs,
      Value<int> idleSecs,
      Value<String> appsJson,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

final class $$HeartbeatsTableReferences
    extends BaseReferences<_$AgentDatabase, $HeartbeatsTable, HeartbeatRow> {
  $$HeartbeatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _localSessionIdTable(_$AgentDatabase db) => db.sessions
      .createAlias('heartbeats__local_session_id__sessions__local_id');

  $$SessionsTableProcessedTableManager get localSessionId {
    final $_column = $_itemColumn<String>('local_session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HeartbeatsTableFilterComposer
    extends Composer<_$AgentDatabase, $HeartbeatsTable> {
  $$HeartbeatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fromTime => $composableBuilder(
    column: $table.fromTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get toTime => $composableBuilder(
    column: $table.toTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeSecs => $composableBuilder(
    column: $table.activeSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idleSecs => $composableBuilder(
    column: $table.idleSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appsJson => $composableBuilder(
    column: $table.appsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get localSessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localSessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartbeatsTableOrderingComposer
    extends Composer<_$AgentDatabase, $HeartbeatsTable> {
  $$HeartbeatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fromTime => $composableBuilder(
    column: $table.fromTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get toTime => $composableBuilder(
    column: $table.toTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeSecs => $composableBuilder(
    column: $table.activeSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idleSecs => $composableBuilder(
    column: $table.idleSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appsJson => $composableBuilder(
    column: $table.appsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get localSessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localSessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartbeatsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $HeartbeatsTable> {
  $$HeartbeatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<DateTime> get fromTime =>
      $composableBuilder(column: $table.fromTime, builder: (column) => column);

  GeneratedColumn<DateTime> get toTime =>
      $composableBuilder(column: $table.toTime, builder: (column) => column);

  GeneratedColumn<int> get activeSecs => $composableBuilder(
    column: $table.activeSecs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get idleSecs =>
      $composableBuilder(column: $table.idleSecs, builder: (column) => column);

  GeneratedColumn<String> get appsJson =>
      $composableBuilder(column: $table.appsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get localSessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localSessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.localId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HeartbeatsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $HeartbeatsTable,
          HeartbeatRow,
          $$HeartbeatsTableFilterComposer,
          $$HeartbeatsTableOrderingComposer,
          $$HeartbeatsTableAnnotationComposer,
          $$HeartbeatsTableCreateCompanionBuilder,
          $$HeartbeatsTableUpdateCompanionBuilder,
          (HeartbeatRow, $$HeartbeatsTableReferences),
          HeartbeatRow,
          PrefetchHooks Function({bool localSessionId})
        > {
  $$HeartbeatsTableTableManager(_$AgentDatabase db, $HeartbeatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeartbeatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeartbeatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeartbeatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> localSessionId = const Value.absent(),
                Value<DateTime> fromTime = const Value.absent(),
                Value<DateTime> toTime = const Value.absent(),
                Value<int> activeSecs = const Value.absent(),
                Value<int> idleSecs = const Value.absent(),
                Value<String> appsJson = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeartbeatsCompanion(
                clientId: clientId,
                localSessionId: localSessionId,
                fromTime: fromTime,
                toTime: toTime,
                activeSecs: activeSecs,
                idleSecs: idleSecs,
                appsJson: appsJson,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String localSessionId,
                required DateTime fromTime,
                required DateTime toTime,
                required int activeSecs,
                required int idleSecs,
                required String appsJson,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HeartbeatsCompanion.insert(
                clientId: clientId,
                localSessionId: localSessionId,
                fromTime: fromTime,
                toTime: toTime,
                activeSecs: activeSecs,
                idleSecs: idleSecs,
                appsJson: appsJson,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HeartbeatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localSessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (localSessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.localSessionId,
                                referencedTable: $$HeartbeatsTableReferences
                                    ._localSessionIdTable(db),
                                referencedColumn: $$HeartbeatsTableReferences
                                    ._localSessionIdTable(db)
                                    .localId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HeartbeatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $HeartbeatsTable,
      HeartbeatRow,
      $$HeartbeatsTableFilterComposer,
      $$HeartbeatsTableOrderingComposer,
      $$HeartbeatsTableAnnotationComposer,
      $$HeartbeatsTableCreateCompanionBuilder,
      $$HeartbeatsTableUpdateCompanionBuilder,
      (HeartbeatRow, $$HeartbeatsTableReferences),
      HeartbeatRow,
      PrefetchHooks Function({bool localSessionId})
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      required String clientId,
      required String kind,
      required String payloadJson,
      Value<int> attempts,
      required DateTime nextAttemptAt,
      required DateTime createdAt,
      Value<String?> lastError,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> id,
      Value<String> clientId,
      Value<String> kind,
      Value<String> payloadJson,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<DateTime> createdAt,
      Value<String?> lastError,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AgentDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AgentDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AgentDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AgentDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AgentDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                clientId: clientId,
                kind: kind,
                payloadJson: payloadJson,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientId,
                required String kind,
                required String payloadJson,
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                required DateTime createdAt,
                Value<String?> lastError = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                clientId: clientId,
                kind: kind,
                payloadJson: payloadJson,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                createdAt: createdAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AgentDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$FileVersionsTableCreateCompanionBuilder =
    FileVersionsCompanion Function({
      required String projectId,
      required String path,
      required String fileId,
      required int version,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$FileVersionsTableUpdateCompanionBuilder =
    FileVersionsCompanion Function({
      Value<String> projectId,
      Value<String> path,
      Value<String> fileId,
      Value<int> version,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$FileVersionsTableFilterComposer
    extends Composer<_$AgentDatabase, $FileVersionsTable> {
  $$FileVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FileVersionsTableOrderingComposer
    extends Composer<_$AgentDatabase, $FileVersionsTable> {
  $$FileVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FileVersionsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $FileVersionsTable> {
  $$FileVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$FileVersionsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $FileVersionsTable,
          FileVersionRow,
          $$FileVersionsTableFilterComposer,
          $$FileVersionsTableOrderingComposer,
          $$FileVersionsTableAnnotationComposer,
          $$FileVersionsTableCreateCompanionBuilder,
          $$FileVersionsTableUpdateCompanionBuilder,
          (
            FileVersionRow,
            BaseReferences<_$AgentDatabase, $FileVersionsTable, FileVersionRow>,
          ),
          FileVersionRow,
          PrefetchHooks Function()
        > {
  $$FileVersionsTableTableManager(_$AgentDatabase db, $FileVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileVersionsCompanion(
                projectId: projectId,
                path: path,
                fileId: fileId,
                version: version,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String path,
                required String fileId,
                required int version,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => FileVersionsCompanion.insert(
                projectId: projectId,
                path: path,
                fileId: fileId,
                version: version,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FileVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $FileVersionsTable,
      FileVersionRow,
      $$FileVersionsTableFilterComposer,
      $$FileVersionsTableOrderingComposer,
      $$FileVersionsTableAnnotationComposer,
      $$FileVersionsTableCreateCompanionBuilder,
      $$FileVersionsTableUpdateCompanionBuilder,
      (
        FileVersionRow,
        BaseReferences<_$AgentDatabase, $FileVersionsTable, FileVersionRow>,
      ),
      FileVersionRow,
      PrefetchHooks Function()
    >;
typedef $$UploadsTableCreateCompanionBuilder =
    UploadsCompanion Function({
      required String clientId,
      required String projectId,
      required String localPath,
      required String remotePath,
      required int size,
      Value<String?> uploadId,
      Value<String> partsJson,
      required String state,
      Value<String> note,
      Value<String?> taskId,
      Value<bool> completeTask,
      Value<int> attempts,
      Value<String?> resultFileId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$UploadsTableUpdateCompanionBuilder =
    UploadsCompanion Function({
      Value<String> clientId,
      Value<String> projectId,
      Value<String> localPath,
      Value<String> remotePath,
      Value<int> size,
      Value<String?> uploadId,
      Value<String> partsJson,
      Value<String> state,
      Value<String> note,
      Value<String?> taskId,
      Value<bool> completeTask,
      Value<int> attempts,
      Value<String?> resultFileId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UploadsTableFilterComposer
    extends Composer<_$AgentDatabase, $UploadsTable> {
  $$UploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completeTask => $composableBuilder(
    column: $table.completeTask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultFileId => $composableBuilder(
    column: $table.resultFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadsTableOrderingComposer
    extends Composer<_$AgentDatabase, $UploadsTable> {
  $$UploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completeTask => $composableBuilder(
    column: $table.completeTask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultFileId => $composableBuilder(
    column: $table.resultFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $UploadsTable> {
  $$UploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get uploadId =>
      $composableBuilder(column: $table.uploadId, builder: (column) => column);

  GeneratedColumn<String> get partsJson =>
      $composableBuilder(column: $table.partsJson, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<bool> get completeTask => $composableBuilder(
    column: $table.completeTask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get resultFileId => $composableBuilder(
    column: $table.resultFileId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UploadsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $UploadsTable,
          UploadRow,
          $$UploadsTableFilterComposer,
          $$UploadsTableOrderingComposer,
          $$UploadsTableAnnotationComposer,
          $$UploadsTableCreateCompanionBuilder,
          $$UploadsTableUpdateCompanionBuilder,
          (
            UploadRow,
            BaseReferences<_$AgentDatabase, $UploadsTable, UploadRow>,
          ),
          UploadRow,
          PrefetchHooks Function()
        > {
  $$UploadsTableTableManager(_$AgentDatabase db, $UploadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> remotePath = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String?> uploadId = const Value.absent(),
                Value<String> partsJson = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<bool> completeTask = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> resultFileId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadsCompanion(
                clientId: clientId,
                projectId: projectId,
                localPath: localPath,
                remotePath: remotePath,
                size: size,
                uploadId: uploadId,
                partsJson: partsJson,
                state: state,
                note: note,
                taskId: taskId,
                completeTask: completeTask,
                attempts: attempts,
                resultFileId: resultFileId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String projectId,
                required String localPath,
                required String remotePath,
                required int size,
                Value<String?> uploadId = const Value.absent(),
                Value<String> partsJson = const Value.absent(),
                required String state,
                Value<String> note = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<bool> completeTask = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> resultFileId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UploadsCompanion.insert(
                clientId: clientId,
                projectId: projectId,
                localPath: localPath,
                remotePath: remotePath,
                size: size,
                uploadId: uploadId,
                partsJson: partsJson,
                state: state,
                note: note,
                taskId: taskId,
                completeTask: completeTask,
                attempts: attempts,
                resultFileId: resultFileId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $UploadsTable,
      UploadRow,
      $$UploadsTableFilterComposer,
      $$UploadsTableOrderingComposer,
      $$UploadsTableAnnotationComposer,
      $$UploadsTableCreateCompanionBuilder,
      $$UploadsTableUpdateCompanionBuilder,
      (UploadRow, BaseReferences<_$AgentDatabase, $UploadsTable, UploadRow>),
      UploadRow,
      PrefetchHooks Function()
    >;
typedef $$DailyReportsTableCreateCompanionBuilder =
    DailyReportsCompanion Function({
      required String date,
      required String workerId,
      required String json,
      Value<bool> submitted,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$DailyReportsTableUpdateCompanionBuilder =
    DailyReportsCompanion Function({
      Value<String> date,
      Value<String> workerId,
      Value<String> json,
      Value<bool> submitted,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$DailyReportsTableFilterComposer
    extends Composer<_$AgentDatabase, $DailyReportsTable> {
  $$DailyReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get submitted => $composableBuilder(
    column: $table.submitted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReportsTableOrderingComposer
    extends Composer<_$AgentDatabase, $DailyReportsTable> {
  $$DailyReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get submitted => $composableBuilder(
    column: $table.submitted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReportsTableAnnotationComposer
    extends Composer<_$AgentDatabase, $DailyReportsTable> {
  $$DailyReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<bool> get submitted =>
      $composableBuilder(column: $table.submitted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$DailyReportsTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $DailyReportsTable,
          DailyReportRow,
          $$DailyReportsTableFilterComposer,
          $$DailyReportsTableOrderingComposer,
          $$DailyReportsTableAnnotationComposer,
          $$DailyReportsTableCreateCompanionBuilder,
          $$DailyReportsTableUpdateCompanionBuilder,
          (
            DailyReportRow,
            BaseReferences<_$AgentDatabase, $DailyReportsTable, DailyReportRow>,
          ),
          DailyReportRow,
          PrefetchHooks Function()
        > {
  $$DailyReportsTableTableManager(_$AgentDatabase db, $DailyReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> workerId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<bool> submitted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion(
                date: date,
                workerId: workerId,
                json: json,
                submitted: submitted,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String workerId,
                required String json,
                Value<bool> submitted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion.insert(
                date: date,
                workerId: workerId,
                json: json,
                submitted: submitted,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $DailyReportsTable,
      DailyReportRow,
      $$DailyReportsTableFilterComposer,
      $$DailyReportsTableOrderingComposer,
      $$DailyReportsTableAnnotationComposer,
      $$DailyReportsTableCreateCompanionBuilder,
      $$DailyReportsTableUpdateCompanionBuilder,
      (
        DailyReportRow,
        BaseReferences<_$AgentDatabase, $DailyReportsTable, DailyReportRow>,
      ),
      DailyReportRow,
      PrefetchHooks Function()
    >;
typedef $$BreaksTableCreateCompanionBuilder =
    BreaksCompanion Function({
      Value<int> id,
      required String day,
      required int piece,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
    });
typedef $$BreaksTableUpdateCompanionBuilder =
    BreaksCompanion Function({
      Value<int> id,
      Value<String> day,
      Value<int> piece,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
    });

class $$BreaksTableFilterComposer
    extends Composer<_$AgentDatabase, $BreaksTable> {
  $$BreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get piece => $composableBuilder(
    column: $table.piece,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BreaksTableOrderingComposer
    extends Composer<_$AgentDatabase, $BreaksTable> {
  $$BreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get piece => $composableBuilder(
    column: $table.piece,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BreaksTableAnnotationComposer
    extends Composer<_$AgentDatabase, $BreaksTable> {
  $$BreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get piece =>
      $composableBuilder(column: $table.piece, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$BreaksTableTableManager
    extends
        RootTableManager<
          _$AgentDatabase,
          $BreaksTable,
          BreakRow,
          $$BreaksTableFilterComposer,
          $$BreaksTableOrderingComposer,
          $$BreaksTableAnnotationComposer,
          $$BreaksTableCreateCompanionBuilder,
          $$BreaksTableUpdateCompanionBuilder,
          (BreakRow, BaseReferences<_$AgentDatabase, $BreaksTable, BreakRow>),
          BreakRow,
          PrefetchHooks Function()
        > {
  $$BreaksTableTableManager(_$AgentDatabase db, $BreaksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> piece = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
              }) => BreaksCompanion(
                id: id,
                day: day,
                piece: piece,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                required int piece,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
              }) => BreaksCompanion.insert(
                id: id,
                day: day,
                piece: piece,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$AgentDatabase,
      $BreaksTable,
      BreakRow,
      $$BreaksTableFilterComposer,
      $$BreaksTableOrderingComposer,
      $$BreaksTableAnnotationComposer,
      $$BreaksTableCreateCompanionBuilder,
      $$BreaksTableUpdateCompanionBuilder,
      (BreakRow, BaseReferences<_$AgentDatabase, $BreaksTable, BreakRow>),
      BreakRow,
      PrefetchHooks Function()
    >;

class $AgentDatabaseManager {
  final _$AgentDatabase _db;
  $AgentDatabaseManager(this._db);
  $$KvEntriesTableTableManager get kvEntries =>
      $$KvEntriesTableTableManager(_db, _db.kvEntries);
  $$CachedProjectsTableTableManager get cachedProjects =>
      $$CachedProjectsTableTableManager(_db, _db.cachedProjects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$HeartbeatsTableTableManager get heartbeats =>
      $$HeartbeatsTableTableManager(_db, _db.heartbeats);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$FileVersionsTableTableManager get fileVersions =>
      $$FileVersionsTableTableManager(_db, _db.fileVersions);
  $$UploadsTableTableManager get uploads =>
      $$UploadsTableTableManager(_db, _db.uploads);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db, _db.dailyReports);
  $$BreaksTableTableManager get breaks =>
      $$BreaksTableTableManager(_db, _db.breaks);
}
