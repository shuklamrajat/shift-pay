// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $JobsTable extends Jobs with TableInfo<$JobsTable, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta('rateCents');
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyLimitMinMeta = const VerificationMeta('dailyLimitMin');
  @override
  late final GeneratedColumn<int> dailyLimitMin = GeneratedColumn<int>(
    'daily_limit_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyDoubleMinMeta = const VerificationMeta('dailyDoubleMin');
  @override
  late final GeneratedColumn<int> dailyDoubleMin = GeneratedColumn<int>(
    'daily_double_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeklyLimitMinMeta = const VerificationMeta('weeklyLimitMin');
  @override
  late final GeneratedColumn<int> weeklyLimitMin = GeneratedColumn<int>(
    'weekly_limit_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otPctMeta = const VerificationMeta('otPct');
  @override
  late final GeneratedColumn<int> otPct = GeneratedColumn<int>(
    'ot_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(150),
  );
  static const VerificationMeta _doublePctMeta = const VerificationMeta('doublePct');
  @override
  late final GeneratedColumn<int> doublePct = GeneratedColumn<int>(
    'double_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(200),
  );
  static const VerificationMeta _weekStartsOnMeta = const VerificationMeta('weekStartsOn');
  @override
  late final GeneratedColumn<int> weekStartsOn = GeneratedColumn<int>(
    'week_starts_on',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(DateTime.monday),
  );
  static const VerificationMeta _workdayStartMinuteMeta = const VerificationMeta('workdayStartMinute');
  @override
  late final GeneratedColumn<int> workdayStartMinute = GeneratedColumn<int>(
    'workday_start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
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
    id,
    name,
    rateCents,
    dailyLimitMin,
    dailyDoubleMin,
    weeklyLimitMin,
    otPct,
    doublePct,
    weekStartsOn,
    workdayStartMinute,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(Insertable<Job> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rate_cents')) {
      context.handle(_rateCentsMeta, rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta));
    } else if (isInserting) {
      context.missing(_rateCentsMeta);
    }
    if (data.containsKey('daily_limit_min')) {
      context.handle(
        _dailyLimitMinMeta,
        dailyLimitMin.isAcceptableOrUnknown(data['daily_limit_min']!, _dailyLimitMinMeta),
      );
    }
    if (data.containsKey('daily_double_min')) {
      context.handle(
        _dailyDoubleMinMeta,
        dailyDoubleMin.isAcceptableOrUnknown(data['daily_double_min']!, _dailyDoubleMinMeta),
      );
    }
    if (data.containsKey('weekly_limit_min')) {
      context.handle(
        _weeklyLimitMinMeta,
        weeklyLimitMin.isAcceptableOrUnknown(data['weekly_limit_min']!, _weeklyLimitMinMeta),
      );
    }
    if (data.containsKey('ot_pct')) {
      context.handle(_otPctMeta, otPct.isAcceptableOrUnknown(data['ot_pct']!, _otPctMeta));
    }
    if (data.containsKey('double_pct')) {
      context.handle(_doublePctMeta, doublePct.isAcceptableOrUnknown(data['double_pct']!, _doublePctMeta));
    }
    if (data.containsKey('week_starts_on')) {
      context.handle(_weekStartsOnMeta, weekStartsOn.isAcceptableOrUnknown(data['week_starts_on']!, _weekStartsOnMeta));
    }
    if (data.containsKey('workday_start_minute')) {
      context.handle(
        _workdayStartMinuteMeta,
        workdayStartMinute.isAcceptableOrUnknown(data['workday_start_minute']!, _workdayStartMinuteMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      rateCents: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rate_cents'])!,
      dailyLimitMin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}daily_limit_min']),
      dailyDoubleMin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}daily_double_min']),
      weeklyLimitMin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}weekly_limit_min']),
      otPct: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ot_pct'])!,
      doublePct: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}double_pct'])!,
      weekStartsOn: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}week_starts_on'])!,
      workdayStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workday_start_minute'],
      )!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class Job extends DataClass implements Insertable<Job> {
  final int id;
  final String name;
  final int rateCents;
  final int? dailyLimitMin;
  final int? dailyDoubleMin;
  final int? weeklyLimitMin;
  final int otPct;
  final int doublePct;
  final int weekStartsOn;
  final int workdayStartMinute;
  final bool archived;
  final DateTime createdAt;
  const Job({
    required this.id,
    required this.name,
    required this.rateCents,
    this.dailyLimitMin,
    this.dailyDoubleMin,
    this.weeklyLimitMin,
    required this.otPct,
    required this.doublePct,
    required this.weekStartsOn,
    required this.workdayStartMinute,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['rate_cents'] = Variable<int>(rateCents);
    if (!nullToAbsent || dailyLimitMin != null) {
      map['daily_limit_min'] = Variable<int>(dailyLimitMin);
    }
    if (!nullToAbsent || dailyDoubleMin != null) {
      map['daily_double_min'] = Variable<int>(dailyDoubleMin);
    }
    if (!nullToAbsent || weeklyLimitMin != null) {
      map['weekly_limit_min'] = Variable<int>(weeklyLimitMin);
    }
    map['ot_pct'] = Variable<int>(otPct);
    map['double_pct'] = Variable<int>(doublePct);
    map['week_starts_on'] = Variable<int>(weekStartsOn);
    map['workday_start_minute'] = Variable<int>(workdayStartMinute);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      name: Value(name),
      rateCents: Value(rateCents),
      dailyLimitMin: dailyLimitMin == null && nullToAbsent ? const Value.absent() : Value(dailyLimitMin),
      dailyDoubleMin: dailyDoubleMin == null && nullToAbsent ? const Value.absent() : Value(dailyDoubleMin),
      weeklyLimitMin: weeklyLimitMin == null && nullToAbsent ? const Value.absent() : Value(weeklyLimitMin),
      otPct: Value(otPct),
      doublePct: Value(doublePct),
      weekStartsOn: Value(weekStartsOn),
      workdayStartMinute: Value(workdayStartMinute),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory Job.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      dailyLimitMin: serializer.fromJson<int?>(json['dailyLimitMin']),
      dailyDoubleMin: serializer.fromJson<int?>(json['dailyDoubleMin']),
      weeklyLimitMin: serializer.fromJson<int?>(json['weeklyLimitMin']),
      otPct: serializer.fromJson<int>(json['otPct']),
      doublePct: serializer.fromJson<int>(json['doublePct']),
      weekStartsOn: serializer.fromJson<int>(json['weekStartsOn']),
      workdayStartMinute: serializer.fromJson<int>(json['workdayStartMinute']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'rateCents': serializer.toJson<int>(rateCents),
      'dailyLimitMin': serializer.toJson<int?>(dailyLimitMin),
      'dailyDoubleMin': serializer.toJson<int?>(dailyDoubleMin),
      'weeklyLimitMin': serializer.toJson<int?>(weeklyLimitMin),
      'otPct': serializer.toJson<int>(otPct),
      'doublePct': serializer.toJson<int>(doublePct),
      'weekStartsOn': serializer.toJson<int>(weekStartsOn),
      'workdayStartMinute': serializer.toJson<int>(workdayStartMinute),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Job copyWith({
    int? id,
    String? name,
    int? rateCents,
    Value<int?> dailyLimitMin = const Value.absent(),
    Value<int?> dailyDoubleMin = const Value.absent(),
    Value<int?> weeklyLimitMin = const Value.absent(),
    int? otPct,
    int? doublePct,
    int? weekStartsOn,
    int? workdayStartMinute,
    bool? archived,
    DateTime? createdAt,
  }) => Job(
    id: id ?? this.id,
    name: name ?? this.name,
    rateCents: rateCents ?? this.rateCents,
    dailyLimitMin: dailyLimitMin.present ? dailyLimitMin.value : this.dailyLimitMin,
    dailyDoubleMin: dailyDoubleMin.present ? dailyDoubleMin.value : this.dailyDoubleMin,
    weeklyLimitMin: weeklyLimitMin.present ? weeklyLimitMin.value : this.weeklyLimitMin,
    otPct: otPct ?? this.otPct,
    doublePct: doublePct ?? this.doublePct,
    weekStartsOn: weekStartsOn ?? this.weekStartsOn,
    workdayStartMinute: workdayStartMinute ?? this.workdayStartMinute,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  Job copyWithCompanion(JobsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      dailyLimitMin: data.dailyLimitMin.present ? data.dailyLimitMin.value : this.dailyLimitMin,
      dailyDoubleMin: data.dailyDoubleMin.present ? data.dailyDoubleMin.value : this.dailyDoubleMin,
      weeklyLimitMin: data.weeklyLimitMin.present ? data.weeklyLimitMin.value : this.weeklyLimitMin,
      otPct: data.otPct.present ? data.otPct.value : this.otPct,
      doublePct: data.doublePct.present ? data.doublePct.value : this.doublePct,
      weekStartsOn: data.weekStartsOn.present ? data.weekStartsOn.value : this.weekStartsOn,
      workdayStartMinute: data.workdayStartMinute.present ? data.workdayStartMinute.value : this.workdayStartMinute,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateCents: $rateCents, ')
          ..write('dailyLimitMin: $dailyLimitMin, ')
          ..write('dailyDoubleMin: $dailyDoubleMin, ')
          ..write('weeklyLimitMin: $weeklyLimitMin, ')
          ..write('otPct: $otPct, ')
          ..write('doublePct: $doublePct, ')
          ..write('weekStartsOn: $weekStartsOn, ')
          ..write('workdayStartMinute: $workdayStartMinute, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    rateCents,
    dailyLimitMin,
    dailyDoubleMin,
    weeklyLimitMin,
    otPct,
    doublePct,
    weekStartsOn,
    workdayStartMinute,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.name == this.name &&
          other.rateCents == this.rateCents &&
          other.dailyLimitMin == this.dailyLimitMin &&
          other.dailyDoubleMin == this.dailyDoubleMin &&
          other.weeklyLimitMin == this.weeklyLimitMin &&
          other.otPct == this.otPct &&
          other.doublePct == this.doublePct &&
          other.weekStartsOn == this.weekStartsOn &&
          other.workdayStartMinute == this.workdayStartMinute &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> rateCents;
  final Value<int?> dailyLimitMin;
  final Value<int?> dailyDoubleMin;
  final Value<int?> weeklyLimitMin;
  final Value<int> otPct;
  final Value<int> doublePct;
  final Value<int> weekStartsOn;
  final Value<int> workdayStartMinute;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.dailyLimitMin = const Value.absent(),
    this.dailyDoubleMin = const Value.absent(),
    this.weeklyLimitMin = const Value.absent(),
    this.otPct = const Value.absent(),
    this.doublePct = const Value.absent(),
    this.weekStartsOn = const Value.absent(),
    this.workdayStartMinute = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  JobsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int rateCents,
    this.dailyLimitMin = const Value.absent(),
    this.dailyDoubleMin = const Value.absent(),
    this.weeklyLimitMin = const Value.absent(),
    this.otPct = const Value.absent(),
    this.doublePct = const Value.absent(),
    this.weekStartsOn = const Value.absent(),
    this.workdayStartMinute = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       rateCents = Value(rateCents),
       createdAt = Value(createdAt);
  static Insertable<Job> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? rateCents,
    Expression<int>? dailyLimitMin,
    Expression<int>? dailyDoubleMin,
    Expression<int>? weeklyLimitMin,
    Expression<int>? otPct,
    Expression<int>? doublePct,
    Expression<int>? weekStartsOn,
    Expression<int>? workdayStartMinute,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rateCents != null) 'rate_cents': rateCents,
      if (dailyLimitMin != null) 'daily_limit_min': dailyLimitMin,
      if (dailyDoubleMin != null) 'daily_double_min': dailyDoubleMin,
      if (weeklyLimitMin != null) 'weekly_limit_min': weeklyLimitMin,
      if (otPct != null) 'ot_pct': otPct,
      if (doublePct != null) 'double_pct': doublePct,
      if (weekStartsOn != null) 'week_starts_on': weekStartsOn,
      if (workdayStartMinute != null) 'workday_start_minute': workdayStartMinute,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  JobsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? rateCents,
    Value<int?>? dailyLimitMin,
    Value<int?>? dailyDoubleMin,
    Value<int?>? weeklyLimitMin,
    Value<int>? otPct,
    Value<int>? doublePct,
    Value<int>? weekStartsOn,
    Value<int>? workdayStartMinute,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rateCents: rateCents ?? this.rateCents,
      dailyLimitMin: dailyLimitMin ?? this.dailyLimitMin,
      dailyDoubleMin: dailyDoubleMin ?? this.dailyDoubleMin,
      weeklyLimitMin: weeklyLimitMin ?? this.weeklyLimitMin,
      otPct: otPct ?? this.otPct,
      doublePct: doublePct ?? this.doublePct,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      workdayStartMinute: workdayStartMinute ?? this.workdayStartMinute,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (dailyLimitMin.present) {
      map['daily_limit_min'] = Variable<int>(dailyLimitMin.value);
    }
    if (dailyDoubleMin.present) {
      map['daily_double_min'] = Variable<int>(dailyDoubleMin.value);
    }
    if (weeklyLimitMin.present) {
      map['weekly_limit_min'] = Variable<int>(weeklyLimitMin.value);
    }
    if (otPct.present) {
      map['ot_pct'] = Variable<int>(otPct.value);
    }
    if (doublePct.present) {
      map['double_pct'] = Variable<int>(doublePct.value);
    }
    if (weekStartsOn.present) {
      map['week_starts_on'] = Variable<int>(weekStartsOn.value);
    }
    if (workdayStartMinute.present) {
      map['workday_start_minute'] = Variable<int>(workdayStartMinute.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateCents: $rateCents, ')
          ..write('dailyLimitMin: $dailyLimitMin, ')
          ..write('dailyDoubleMin: $dailyDoubleMin, ')
          ..write('weeklyLimitMin: $weeklyLimitMin, ')
          ..write('otPct: $otPct, ')
          ..write('doublePct: $doublePct, ')
          ..write('weekStartsOn: $weekStartsOn, ')
          ..write('workdayStartMinute: $workdayStartMinute, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, Shift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES jobs (id)'),
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unpaidBreakMinMeta = const VerificationMeta('unpaidBreakMin');
  @override
  late final GeneratedColumn<int> unpaidBreakMin = GeneratedColumn<int>(
    'unpaid_break_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta('rateCents');
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jobId, start, end, unpaidBreakMin, rateCents, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(Insertable<Shift> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(_jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(_startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(_endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    }
    if (data.containsKey('unpaid_break_min')) {
      context.handle(
        _unpaidBreakMinMeta,
        unpaidBreakMin.isAcceptableOrUnknown(data['unpaid_break_min']!, _unpaidBreakMinMeta),
      );
    }
    if (data.containsKey('rate_cents')) {
      context.handle(_rateCentsMeta, rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta));
    } else if (isInserting) {
      context.missing(_rateCentsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shift(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}job_id'])!,
      start: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}end']),
      unpaidBreakMin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}unpaid_break_min'])!,
      rateCents: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rate_cents'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final int id;
  final int jobId;
  final DateTime start;

  /// Null while clocked in.
  final DateTime? end;
  final int unpaidBreakMin;

  /// Rate at the time the shift was logged, so raises don't reprice history.
  final int rateCents;
  final String note;
  final DateTime updatedAt;
  const Shift({
    required this.id,
    required this.jobId,
    required this.start,
    this.end,
    required this.unpaidBreakMin,
    required this.rateCents,
    required this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<int>(jobId);
    map['start'] = Variable<DateTime>(start);
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<DateTime>(end);
    }
    map['unpaid_break_min'] = Variable<int>(unpaidBreakMin);
    map['rate_cents'] = Variable<int>(rateCents);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      start: Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
      unpaidBreakMin: Value(unpaidBreakMin),
      rateCents: Value(rateCents),
      note: Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<int>(json['jobId']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime?>(json['end']),
      unpaidBreakMin: serializer.fromJson<int>(json['unpaidBreakMin']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<int>(jobId),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime?>(end),
      'unpaidBreakMin': serializer.toJson<int>(unpaidBreakMin),
      'rateCents': serializer.toJson<int>(rateCents),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Shift copyWith({
    int? id,
    int? jobId,
    DateTime? start,
    Value<DateTime?> end = const Value.absent(),
    int? unpaidBreakMin,
    int? rateCents,
    String? note,
    DateTime? updatedAt,
  }) => Shift(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    start: start ?? this.start,
    end: end.present ? end.value : this.end,
    unpaidBreakMin: unpaidBreakMin ?? this.unpaidBreakMin,
    rateCents: rateCents ?? this.rateCents,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      unpaidBreakMin: data.unpaidBreakMin.present ? data.unpaidBreakMin.value : this.unpaidBreakMin,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('unpaidBreakMin: $unpaidBreakMin, ')
          ..write('rateCents: $rateCents, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, start, end, unpaidBreakMin, rateCents, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.start == this.start &&
          other.end == this.end &&
          other.unpaidBreakMin == this.unpaidBreakMin &&
          other.rateCents == this.rateCents &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<int> id;
  final Value<int> jobId;
  final Value<DateTime> start;
  final Value<DateTime?> end;
  final Value<int> unpaidBreakMin;
  final Value<int> rateCents;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.unpaidBreakMin = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int jobId,
    required DateTime start,
    this.end = const Value.absent(),
    this.unpaidBreakMin = const Value.absent(),
    required int rateCents,
    this.note = const Value.absent(),
    required DateTime updatedAt,
  }) : jobId = Value(jobId),
       start = Value(start),
       rateCents = Value(rateCents),
       updatedAt = Value(updatedAt);
  static Insertable<Shift> custom({
    Expression<int>? id,
    Expression<int>? jobId,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<int>? unpaidBreakMin,
    Expression<int>? rateCents,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (unpaidBreakMin != null) 'unpaid_break_min': unpaidBreakMin,
      if (rateCents != null) 'rate_cents': rateCents,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShiftsCompanion copyWith({
    Value<int>? id,
    Value<int>? jobId,
    Value<DateTime>? start,
    Value<DateTime?>? end,
    Value<int>? unpaidBreakMin,
    Value<int>? rateCents,
    Value<String>? note,
    Value<DateTime>? updatedAt,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      start: start ?? this.start,
      end: end ?? this.end,
      unpaidBreakMin: unpaidBreakMin ?? this.unpaidBreakMin,
      rateCents: rateCents ?? this.rateCents,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<int>(jobId.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (unpaidBreakMin.present) {
      map['unpaid_break_min'] = Variable<int>(unpaidBreakMin.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('unpaidBreakMin: $unpaidBreakMin, ')
          ..write('rateCents: $rateCents, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$HoursDb extends GeneratedDatabase {
  _$HoursDb(QueryExecutor e) : super(e);
  $HoursDbManager get managers => $HoursDbManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [jobs, shifts];
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  required String name,
  required int rateCents,
  Value<int?> dailyLimitMin,
  Value<int?> dailyDoubleMin,
  Value<int?> weeklyLimitMin,
  Value<int> otPct,
  Value<int> doublePct,
  Value<int> weekStartsOn,
  Value<int> workdayStartMinute,
  Value<bool> archived,
  required DateTime createdAt,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> rateCents,
  Value<int?> dailyLimitMin,
  Value<int?> dailyDoubleMin,
  Value<int?> weeklyLimitMin,
  Value<int> otPct,
  Value<int> doublePct,
  Value<int> weekStartsOn,
  Value<int> workdayStartMinute,
  Value<bool> archived,
  Value<DateTime> createdAt,
});

final class $$JobsTableReferences extends BaseReferences<_$HoursDb, $JobsTable, Job> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShiftsTable, List<Shift>> _shiftsRefsTable(_$HoursDb db) =>
      MultiTypedResultKey.fromTable(db.shifts, aliasName: 'jobs__id__shifts__job_id');

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$JobsTableFilterComposer extends Composer<_$HoursDb, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyLimitMin =>
      $composableBuilder(column: $table.dailyLimitMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyDoubleMin =>
      $composableBuilder(column: $table.dailyDoubleMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weeklyLimitMin =>
      $composableBuilder(column: $table.weeklyLimitMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get otPct => $composableBuilder(column: $table.otPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get doublePct =>
      $composableBuilder(column: $table.doublePct, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekStartsOn =>
      $composableBuilder(column: $table.weekStartsOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workdayStartMinute =>
      $composableBuilder(column: $table.workdayStartMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> shiftsRefs(Expression<bool> Function($$ShiftsTableFilterComposer f) f) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableOrderingComposer extends Composer<_$HoursDb, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyLimitMin =>
      $composableBuilder(column: $table.dailyLimitMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyDoubleMin =>
      $composableBuilder(column: $table.dailyDoubleMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weeklyLimitMin =>
      $composableBuilder(column: $table.weeklyLimitMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get otPct =>
      $composableBuilder(column: $table.otPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get doublePct =>
      $composableBuilder(column: $table.doublePct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekStartsOn =>
      $composableBuilder(column: $table.weekStartsOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workdayStartMinute =>
      $composableBuilder(column: $table.workdayStartMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$JobsTableAnnotationComposer extends Composer<_$HoursDb, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get rateCents => $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<int> get dailyLimitMin =>
      $composableBuilder(column: $table.dailyLimitMin, builder: (column) => column);

  GeneratedColumn<int> get dailyDoubleMin =>
      $composableBuilder(column: $table.dailyDoubleMin, builder: (column) => column);

  GeneratedColumn<int> get weeklyLimitMin =>
      $composableBuilder(column: $table.weeklyLimitMin, builder: (column) => column);

  GeneratedColumn<int> get otPct => $composableBuilder(column: $table.otPct, builder: (column) => column);

  GeneratedColumn<int> get doublePct => $composableBuilder(column: $table.doublePct, builder: (column) => column);

  GeneratedColumn<int> get weekStartsOn => $composableBuilder(column: $table.weekStartsOn, builder: (column) => column);

  GeneratedColumn<int> get workdayStartMinute =>
      $composableBuilder(column: $table.workdayStartMinute, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> shiftsRefs<T extends Object>(Expression<T> Function($$ShiftsTableAnnotationComposer a) f) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$HoursDb,
          $JobsTable,
          Job,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (Job, $$JobsTableReferences),
          Job,
          PrefetchHooks Function({bool shiftsRefs})
        > {
  $$JobsTableTableManager(_$HoursDb db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<int?> dailyLimitMin = const Value.absent(),
                Value<int?> dailyDoubleMin = const Value.absent(),
                Value<int?> weeklyLimitMin = const Value.absent(),
                Value<int> otPct = const Value.absent(),
                Value<int> doublePct = const Value.absent(),
                Value<int> weekStartsOn = const Value.absent(),
                Value<int> workdayStartMinute = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                name: name,
                rateCents: rateCents,
                dailyLimitMin: dailyLimitMin,
                dailyDoubleMin: dailyDoubleMin,
                weeklyLimitMin: weeklyLimitMin,
                otPct: otPct,
                doublePct: doublePct,
                weekStartsOn: weekStartsOn,
                workdayStartMinute: workdayStartMinute,
                archived: archived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int rateCents,
                Value<int?> dailyLimitMin = const Value.absent(),
                Value<int?> dailyDoubleMin = const Value.absent(),
                Value<int?> weeklyLimitMin = const Value.absent(),
                Value<int> otPct = const Value.absent(),
                Value<int> doublePct = const Value.absent(),
                Value<int> weekStartsOn = const Value.absent(),
                Value<int> workdayStartMinute = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
              }) => JobsCompanion.insert(
                id: id,
                name: name,
                rateCents: rateCents,
                dailyLimitMin: dailyLimitMin,
                dailyDoubleMin: dailyDoubleMin,
                weeklyLimitMin: weeklyLimitMin,
                otPct: otPct,
                doublePct: doublePct,
                weekStartsOn: weekStartsOn,
                workdayStartMinute: workdayStartMinute,
                archived: archived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$JobsTable, Job>(table), $$JobsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({shiftsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shiftsRefs) db.shifts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shiftsRefs)
                    await $_getPrefetchedDataByColumns<Job, $JobsTable, Shift, $ShiftsTable>(
                      currentTable: table,
                      referencedTable: $$JobsTableReferences._shiftsRefsTable(db),
                      managerFromTypedResult: (p0) => $$JobsTableReferences(db, table, p0).shiftsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'job_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$HoursDb,
      $JobsTable,
      Job,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (Job, $$JobsTableReferences),
      Job,
      PrefetchHooks Function({bool shiftsRefs})
    >;
typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  required int jobId,
  required DateTime start,
  Value<DateTime?> end,
  Value<int> unpaidBreakMin,
  required int rateCents,
  Value<String> note,
  required DateTime updatedAt,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int> jobId,
  Value<DateTime> start,
  Value<DateTime?> end,
  Value<int> unpaidBreakMin,
  Value<int> rateCents,
  Value<String> note,
  Value<DateTime> updatedAt,
});

final class $$ShiftsTableReferences extends BaseReferences<_$HoursDb, $ShiftsTable, Shift> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JobsTable _jobIdTable(_$HoursDb db) => db.jobs.createAlias('shifts__job_id__jobs__id');

  $$JobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<int>('job_id')!;

    final manager = $$JobsTableTableManager($_db, $_db.jobs).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ShiftsTableFilterComposer extends Composer<_$HoursDb, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get end => $composableBuilder(column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unpaidBreakMin =>
      $composableBuilder(column: $table.unpaidBreakMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableOrderingComposer extends Composer<_$HoursDb, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unpaidBreakMin =>
      $composableBuilder(column: $table.unpaidBreakMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer extends Composer<_$HoursDb, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get start => $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end => $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<int> get unpaidBreakMin =>
      $composableBuilder(column: $table.unpaidBreakMin, builder: (column) => column);

  GeneratedColumn<int> get rateCents => $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$HoursDb,
          $ShiftsTable,
          Shift,
          $$ShiftsTableFilterComposer,
          $$ShiftsTableOrderingComposer,
          $$ShiftsTableAnnotationComposer,
          $$ShiftsTableCreateCompanionBuilder,
          $$ShiftsTableUpdateCompanionBuilder,
          (Shift, $$ShiftsTableReferences),
          Shift,
          PrefetchHooks Function({bool jobId})
        > {
  $$ShiftsTableTableManager(_$HoursDb db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> jobId = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime?> end = const Value.absent(),
                Value<int> unpaidBreakMin = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                jobId: jobId,
                start: start,
                end: end,
                unpaidBreakMin: unpaidBreakMin,
                rateCents: rateCents,
                note: note,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int jobId,
                required DateTime start,
                Value<DateTime?> end = const Value.absent(),
                Value<int> unpaidBreakMin = const Value.absent(),
                required int rateCents,
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
              }) => ShiftsCompanion.insert(
                id: id,
                jobId: jobId,
                start: start,
                end: end,
                unpaidBreakMin: unpaidBreakMin,
                rateCents: rateCents,
                note: note,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$ShiftsTable, Shift>(table), $$ShiftsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({jobId = false}) {
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
                    if (jobId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.jobId,
                        referencedTable: $$ShiftsTableReferences._jobIdTable(db),
                        referencedColumn: $$ShiftsTableReferences._jobIdTable(db).id,
                      ) as T;
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

typedef $$ShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$HoursDb,
      $ShiftsTable,
      Shift,
      $$ShiftsTableFilterComposer,
      $$ShiftsTableOrderingComposer,
      $$ShiftsTableAnnotationComposer,
      $$ShiftsTableCreateCompanionBuilder,
      $$ShiftsTableUpdateCompanionBuilder,
      (Shift, $$ShiftsTableReferences),
      Shift,
      PrefetchHooks Function({bool jobId})
    >;

class $HoursDbManager {
  final _$HoursDb _db;
  $HoursDbManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$ShiftsTableTableManager get shifts => $$ShiftsTableTableManager(_db, _db.shifts);
}
