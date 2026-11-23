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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('server'),
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta(
    'rateCents',
  );
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tipOutKindMeta = const VerificationMeta(
    'tipOutKind',
  );
  @override
  late final GeneratedColumn<String> tipOutKind = GeneratedColumn<String>(
    'tip_out_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _tipOutValueMeta = const VerificationMeta(
    'tipOutValue',
  );
  @override
  late final GeneratedColumn<int> tipOutValue = GeneratedColumn<int>(
    'tip_out_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tracksSalesMeta = const VerificationMeta(
    'tracksSales',
  );
  @override
  late final GeneratedColumn<bool> tracksSales = GeneratedColumn<bool>(
    'tracks_sales',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_sales" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _payKindMeta = const VerificationMeta(
    'payKind',
  );
  @override
  late final GeneratedColumn<String> payKind = GeneratedColumn<String>(
    'pay_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payAnchorMeta = const VerificationMeta(
    'payAnchor',
  );
  @override
  late final GeneratedColumn<String> payAnchor = GeneratedColumn<String>(
    'pay_anchor',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    role,
    rateCents,
    tipOutKind,
    tipOutValue,
    tracksSales,
    colorIndex,
    archived,
    createdAt,
    payKind,
    payAnchor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Job> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('rate_cents')) {
      context.handle(
        _rateCentsMeta,
        rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta),
      );
    }
    if (data.containsKey('tip_out_kind')) {
      context.handle(
        _tipOutKindMeta,
        tipOutKind.isAcceptableOrUnknown(
          data['tip_out_kind']!,
          _tipOutKindMeta,
        ),
      );
    }
    if (data.containsKey('tip_out_value')) {
      context.handle(
        _tipOutValueMeta,
        tipOutValue.isAcceptableOrUnknown(
          data['tip_out_value']!,
          _tipOutValueMeta,
        ),
      );
    }
    if (data.containsKey('tracks_sales')) {
      context.handle(
        _tracksSalesMeta,
        tracksSales.isAcceptableOrUnknown(
          data['tracks_sales']!,
          _tracksSalesMeta,
        ),
      );
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
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
    if (data.containsKey('pay_kind')) {
      context.handle(
        _payKindMeta,
        payKind.isAcceptableOrUnknown(data['pay_kind']!, _payKindMeta),
      );
    }
    if (data.containsKey('pay_anchor')) {
      context.handle(
        _payAnchorMeta,
        payAnchor.isAcceptableOrUnknown(data['pay_anchor']!, _payAnchorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      rateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_cents'],
      )!,
      tipOutKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tip_out_kind'],
      )!,
      tipOutValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tip_out_value'],
      )!,
      tracksSales: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_sales'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      payKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pay_kind'],
      ),
      payAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pay_anchor'],
      ),
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

  /// server, bartender, delivery, other.
  final String role;
  final int rateCents;

  /// TipOutKind name.
  final String tipOutKind;

  /// Basis points for % rules, cents for flat.
  final int tipOutValue;
  final bool tracksSales;
  final int colorIndex;
  final bool archived;
  final DateTime createdAt;

  /// This job's pay period (PayPeriodKind name) and a day one started on
  /// ("YYYY-MM-DD"). Null means it follows the default in Settings.
  final String? payKind;
  final String? payAnchor;
  const Job({
    required this.id,
    required this.name,
    required this.role,
    required this.rateCents,
    required this.tipOutKind,
    required this.tipOutValue,
    required this.tracksSales,
    required this.colorIndex,
    required this.archived,
    required this.createdAt,
    this.payKind,
    this.payAnchor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    map['rate_cents'] = Variable<int>(rateCents);
    map['tip_out_kind'] = Variable<String>(tipOutKind);
    map['tip_out_value'] = Variable<int>(tipOutValue);
    map['tracks_sales'] = Variable<bool>(tracksSales);
    map['color_index'] = Variable<int>(colorIndex);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || payKind != null) {
      map['pay_kind'] = Variable<String>(payKind);
    }
    if (!nullToAbsent || payAnchor != null) {
      map['pay_anchor'] = Variable<String>(payAnchor);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      rateCents: Value(rateCents),
      tipOutKind: Value(tipOutKind),
      tipOutValue: Value(tipOutValue),
      tracksSales: Value(tracksSales),
      colorIndex: Value(colorIndex),
      archived: Value(archived),
      createdAt: Value(createdAt),
      payKind: payKind == null && nullToAbsent
          ? const Value.absent()
          : Value(payKind),
      payAnchor: payAnchor == null && nullToAbsent
          ? const Value.absent()
          : Value(payAnchor),
    );
  }

  factory Job.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      tipOutKind: serializer.fromJson<String>(json['tipOutKind']),
      tipOutValue: serializer.fromJson<int>(json['tipOutValue']),
      tracksSales: serializer.fromJson<bool>(json['tracksSales']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      payKind: serializer.fromJson<String?>(json['payKind']),
      payAnchor: serializer.fromJson<String?>(json['payAnchor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'rateCents': serializer.toJson<int>(rateCents),
      'tipOutKind': serializer.toJson<String>(tipOutKind),
      'tipOutValue': serializer.toJson<int>(tipOutValue),
      'tracksSales': serializer.toJson<bool>(tracksSales),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'payKind': serializer.toJson<String?>(payKind),
      'payAnchor': serializer.toJson<String?>(payAnchor),
    };
  }

  Job copyWith({
    int? id,
    String? name,
    String? role,
    int? rateCents,
    String? tipOutKind,
    int? tipOutValue,
    bool? tracksSales,
    int? colorIndex,
    bool? archived,
    DateTime? createdAt,
    Value<String?> payKind = const Value.absent(),
    Value<String?> payAnchor = const Value.absent(),
  }) => Job(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    rateCents: rateCents ?? this.rateCents,
    tipOutKind: tipOutKind ?? this.tipOutKind,
    tipOutValue: tipOutValue ?? this.tipOutValue,
    tracksSales: tracksSales ?? this.tracksSales,
    colorIndex: colorIndex ?? this.colorIndex,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    payKind: payKind.present ? payKind.value : this.payKind,
    payAnchor: payAnchor.present ? payAnchor.value : this.payAnchor,
  );
  Job copyWithCompanion(JobsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      tipOutKind: data.tipOutKind.present
          ? data.tipOutKind.value
          : this.tipOutKind,
      tipOutValue: data.tipOutValue.present
          ? data.tipOutValue.value
          : this.tipOutValue,
      tracksSales: data.tracksSales.present
          ? data.tracksSales.value
          : this.tracksSales,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      payKind: data.payKind.present ? data.payKind.value : this.payKind,
      payAnchor: data.payAnchor.present ? data.payAnchor.value : this.payAnchor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('rateCents: $rateCents, ')
          ..write('tipOutKind: $tipOutKind, ')
          ..write('tipOutValue: $tipOutValue, ')
          ..write('tracksSales: $tracksSales, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('payKind: $payKind, ')
          ..write('payAnchor: $payAnchor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    role,
    rateCents,
    tipOutKind,
    tipOutValue,
    tracksSales,
    colorIndex,
    archived,
    createdAt,
    payKind,
    payAnchor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.rateCents == this.rateCents &&
          other.tipOutKind == this.tipOutKind &&
          other.tipOutValue == this.tipOutValue &&
          other.tracksSales == this.tracksSales &&
          other.colorIndex == this.colorIndex &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.payKind == this.payKind &&
          other.payAnchor == this.payAnchor);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> role;
  final Value<int> rateCents;
  final Value<String> tipOutKind;
  final Value<int> tipOutValue;
  final Value<bool> tracksSales;
  final Value<int> colorIndex;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<String?> payKind;
  final Value<String?> payAnchor;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.tipOutKind = const Value.absent(),
    this.tipOutValue = const Value.absent(),
    this.tracksSales = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.payKind = const Value.absent(),
    this.payAnchor = const Value.absent(),
  });
  JobsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.role = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.tipOutKind = const Value.absent(),
    this.tipOutValue = const Value.absent(),
    this.tracksSales = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    this.payKind = const Value.absent(),
    this.payAnchor = const Value.absent(),
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Job> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<int>? rateCents,
    Expression<String>? tipOutKind,
    Expression<int>? tipOutValue,
    Expression<bool>? tracksSales,
    Expression<int>? colorIndex,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<String>? payKind,
    Expression<String>? payAnchor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (rateCents != null) 'rate_cents': rateCents,
      if (tipOutKind != null) 'tip_out_kind': tipOutKind,
      if (tipOutValue != null) 'tip_out_value': tipOutValue,
      if (tracksSales != null) 'tracks_sales': tracksSales,
      if (colorIndex != null) 'color_index': colorIndex,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (payKind != null) 'pay_kind': payKind,
      if (payAnchor != null) 'pay_anchor': payAnchor,
    });
  }

  JobsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? role,
    Value<int>? rateCents,
    Value<String>? tipOutKind,
    Value<int>? tipOutValue,
    Value<bool>? tracksSales,
    Value<int>? colorIndex,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<String?>? payKind,
    Value<String?>? payAnchor,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      rateCents: rateCents ?? this.rateCents,
      tipOutKind: tipOutKind ?? this.tipOutKind,
      tipOutValue: tipOutValue ?? this.tipOutValue,
      tracksSales: tracksSales ?? this.tracksSales,
      colorIndex: colorIndex ?? this.colorIndex,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      payKind: payKind ?? this.payKind,
      payAnchor: payAnchor ?? this.payAnchor,
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
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (tipOutKind.present) {
      map['tip_out_kind'] = Variable<String>(tipOutKind.value);
    }
    if (tipOutValue.present) {
      map['tip_out_value'] = Variable<int>(tipOutValue.value);
    }
    if (tracksSales.present) {
      map['tracks_sales'] = Variable<bool>(tracksSales.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (payKind.present) {
      map['pay_kind'] = Variable<String>(payKind.value);
    }
    if (payAnchor.present) {
      map['pay_anchor'] = Variable<String>(payAnchor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('rateCents: $rateCents, ')
          ..write('tipOutKind: $tipOutKind, ')
          ..write('tipOutValue: $tipOutValue, ')
          ..write('tracksSales: $tracksSales, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('payKind: $payKind, ')
          ..write('payAnchor: $payAnchor')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id)',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breakMinutesMeta = const VerificationMeta(
    'breakMinutes',
  );
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
    'break_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashCentsMeta = const VerificationMeta(
    'cashCents',
  );
  @override
  late final GeneratedColumn<int> cashCents = GeneratedColumn<int>(
    'cash_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cardCentsMeta = const VerificationMeta(
    'cardCents',
  );
  @override
  late final GeneratedColumn<int> cardCents = GeneratedColumn<int>(
    'card_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tipInCentsMeta = const VerificationMeta(
    'tipInCents',
  );
  @override
  late final GeneratedColumn<int> tipInCents = GeneratedColumn<int>(
    'tip_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _salesCentsMeta = const VerificationMeta(
    'salesCents',
  );
  @override
  late final GeneratedColumn<int> salesCents = GeneratedColumn<int>(
    'sales_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tipOutCentsMeta = const VerificationMeta(
    'tipOutCents',
  );
  @override
  late final GeneratedColumn<int> tipOutCents = GeneratedColumn<int>(
    'tip_out_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tipOutEditedMeta = const VerificationMeta(
    'tipOutEdited',
  );
  @override
  late final GeneratedColumn<bool> tipOutEdited = GeneratedColumn<bool>(
    'tip_out_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tip_out_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rateCentsMeta = const VerificationMeta(
    'rateCents',
  );
  @override
  late final GeneratedColumn<int> rateCents = GeneratedColumn<int>(
    'rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleKindMeta = const VerificationMeta(
    'ruleKind',
  );
  @override
  late final GeneratedColumn<String> ruleKind = GeneratedColumn<String>(
    'rule_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _ruleValueMeta = const VerificationMeta(
    'ruleValue',
  );
  @override
  late final GeneratedColumn<int> ruleValue = GeneratedColumn<int>(
    'rule_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    day,
    startMinute,
    endMinute,
    breakMinutes,
    minutes,
    cashCents,
    cardCents,
    tipInCents,
    salesCents,
    tipOutCents,
    tipOutEdited,
    rateCents,
    ruleKind,
    ruleValue,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
        _breakMinutesMeta,
        breakMinutes.isAcceptableOrUnknown(
          data['break_minutes']!,
          _breakMinutesMeta,
        ),
      );
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('cash_cents')) {
      context.handle(
        _cashCentsMeta,
        cashCents.isAcceptableOrUnknown(data['cash_cents']!, _cashCentsMeta),
      );
    }
    if (data.containsKey('card_cents')) {
      context.handle(
        _cardCentsMeta,
        cardCents.isAcceptableOrUnknown(data['card_cents']!, _cardCentsMeta),
      );
    }
    if (data.containsKey('tip_in_cents')) {
      context.handle(
        _tipInCentsMeta,
        tipInCents.isAcceptableOrUnknown(
          data['tip_in_cents']!,
          _tipInCentsMeta,
        ),
      );
    }
    if (data.containsKey('sales_cents')) {
      context.handle(
        _salesCentsMeta,
        salesCents.isAcceptableOrUnknown(data['sales_cents']!, _salesCentsMeta),
      );
    }
    if (data.containsKey('tip_out_cents')) {
      context.handle(
        _tipOutCentsMeta,
        tipOutCents.isAcceptableOrUnknown(
          data['tip_out_cents']!,
          _tipOutCentsMeta,
        ),
      );
    }
    if (data.containsKey('tip_out_edited')) {
      context.handle(
        _tipOutEditedMeta,
        tipOutEdited.isAcceptableOrUnknown(
          data['tip_out_edited']!,
          _tipOutEditedMeta,
        ),
      );
    }
    if (data.containsKey('rate_cents')) {
      context.handle(
        _rateCentsMeta,
        rateCents.isAcceptableOrUnknown(data['rate_cents']!, _rateCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_rateCentsMeta);
    }
    if (data.containsKey('rule_kind')) {
      context.handle(
        _ruleKindMeta,
        ruleKind.isAcceptableOrUnknown(data['rule_kind']!, _ruleKindMeta),
      );
    }
    if (data.containsKey('rule_value')) {
      context.handle(
        _ruleValueMeta,
        ruleValue.isAcceptableOrUnknown(data['rule_value']!, _ruleValueMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}job_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      ),
      breakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_minutes'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      cashCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_cents'],
      )!,
      cardCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_cents'],
      )!,
      tipInCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tip_in_cents'],
      )!,
      salesCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sales_cents'],
      ),
      tipOutCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tip_out_cents'],
      )!,
      tipOutEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tip_out_edited'],
      )!,
      rateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_cents'],
      )!,
      ruleKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_kind'],
      )!,
      ruleValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_value'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
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

  /// "YYYY-MM-DD", the day the shift started.
  final String day;

  /// Minute of the day, or null when only hours were typed.
  final int? startMinute;
  final int? endMinute;
  final int breakMinutes;

  /// Paid minutes worked (end - start - break, or the typed hours).
  final int minutes;
  final int cashCents;
  final int cardCents;
  final int tipInCents;
  final int? salesCents;

  /// The tip-out actually paid that night.
  final int tipOutCents;
  final bool tipOutEdited;

  /// Wage and rule in force when the shift was saved, so a raise or a new
  /// rule never reprices old nights.
  final int rateCents;
  final String ruleKind;
  final int ruleValue;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Shift({
    required this.id,
    required this.jobId,
    required this.day,
    this.startMinute,
    this.endMinute,
    required this.breakMinutes,
    required this.minutes,
    required this.cashCents,
    required this.cardCents,
    required this.tipInCents,
    this.salesCents,
    required this.tipOutCents,
    required this.tipOutEdited,
    required this.rateCents,
    required this.ruleKind,
    required this.ruleValue,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<int>(jobId);
    map['day'] = Variable<String>(day);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    map['break_minutes'] = Variable<int>(breakMinutes);
    map['minutes'] = Variable<int>(minutes);
    map['cash_cents'] = Variable<int>(cashCents);
    map['card_cents'] = Variable<int>(cardCents);
    map['tip_in_cents'] = Variable<int>(tipInCents);
    if (!nullToAbsent || salesCents != null) {
      map['sales_cents'] = Variable<int>(salesCents);
    }
    map['tip_out_cents'] = Variable<int>(tipOutCents);
    map['tip_out_edited'] = Variable<bool>(tipOutEdited);
    map['rate_cents'] = Variable<int>(rateCents);
    map['rule_kind'] = Variable<String>(ruleKind);
    map['rule_value'] = Variable<int>(ruleValue);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      day: Value(day),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      breakMinutes: Value(breakMinutes),
      minutes: Value(minutes),
      cashCents: Value(cashCents),
      cardCents: Value(cardCents),
      tipInCents: Value(tipInCents),
      salesCents: salesCents == null && nullToAbsent
          ? const Value.absent()
          : Value(salesCents),
      tipOutCents: Value(tipOutCents),
      tipOutEdited: Value(tipOutEdited),
      rateCents: Value(rateCents),
      ruleKind: Value(ruleKind),
      ruleValue: Value(ruleValue),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Shift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<int>(json['jobId']),
      day: serializer.fromJson<String>(json['day']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      breakMinutes: serializer.fromJson<int>(json['breakMinutes']),
      minutes: serializer.fromJson<int>(json['minutes']),
      cashCents: serializer.fromJson<int>(json['cashCents']),
      cardCents: serializer.fromJson<int>(json['cardCents']),
      tipInCents: serializer.fromJson<int>(json['tipInCents']),
      salesCents: serializer.fromJson<int?>(json['salesCents']),
      tipOutCents: serializer.fromJson<int>(json['tipOutCents']),
      tipOutEdited: serializer.fromJson<bool>(json['tipOutEdited']),
      rateCents: serializer.fromJson<int>(json['rateCents']),
      ruleKind: serializer.fromJson<String>(json['ruleKind']),
      ruleValue: serializer.fromJson<int>(json['ruleValue']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<int>(jobId),
      'day': serializer.toJson<String>(day),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'breakMinutes': serializer.toJson<int>(breakMinutes),
      'minutes': serializer.toJson<int>(minutes),
      'cashCents': serializer.toJson<int>(cashCents),
      'cardCents': serializer.toJson<int>(cardCents),
      'tipInCents': serializer.toJson<int>(tipInCents),
      'salesCents': serializer.toJson<int?>(salesCents),
      'tipOutCents': serializer.toJson<int>(tipOutCents),
      'tipOutEdited': serializer.toJson<bool>(tipOutEdited),
      'rateCents': serializer.toJson<int>(rateCents),
      'ruleKind': serializer.toJson<String>(ruleKind),
      'ruleValue': serializer.toJson<int>(ruleValue),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Shift copyWith({
    int? id,
    int? jobId,
    String? day,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    int? breakMinutes,
    int? minutes,
    int? cashCents,
    int? cardCents,
    int? tipInCents,
    Value<int?> salesCents = const Value.absent(),
    int? tipOutCents,
    bool? tipOutEdited,
    int? rateCents,
    String? ruleKind,
    int? ruleValue,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Shift(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    day: day ?? this.day,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    minutes: minutes ?? this.minutes,
    cashCents: cashCents ?? this.cashCents,
    cardCents: cardCents ?? this.cardCents,
    tipInCents: tipInCents ?? this.tipInCents,
    salesCents: salesCents.present ? salesCents.value : this.salesCents,
    tipOutCents: tipOutCents ?? this.tipOutCents,
    tipOutEdited: tipOutEdited ?? this.tipOutEdited,
    rateCents: rateCents ?? this.rateCents,
    ruleKind: ruleKind ?? this.ruleKind,
    ruleValue: ruleValue ?? this.ruleValue,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      day: data.day.present ? data.day.value : this.day,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      cashCents: data.cashCents.present ? data.cashCents.value : this.cashCents,
      cardCents: data.cardCents.present ? data.cardCents.value : this.cardCents,
      tipInCents: data.tipInCents.present
          ? data.tipInCents.value
          : this.tipInCents,
      salesCents: data.salesCents.present
          ? data.salesCents.value
          : this.salesCents,
      tipOutCents: data.tipOutCents.present
          ? data.tipOutCents.value
          : this.tipOutCents,
      tipOutEdited: data.tipOutEdited.present
          ? data.tipOutEdited.value
          : this.tipOutEdited,
      rateCents: data.rateCents.present ? data.rateCents.value : this.rateCents,
      ruleKind: data.ruleKind.present ? data.ruleKind.value : this.ruleKind,
      ruleValue: data.ruleValue.present ? data.ruleValue.value : this.ruleValue,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('day: $day, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('minutes: $minutes, ')
          ..write('cashCents: $cashCents, ')
          ..write('cardCents: $cardCents, ')
          ..write('tipInCents: $tipInCents, ')
          ..write('salesCents: $salesCents, ')
          ..write('tipOutCents: $tipOutCents, ')
          ..write('tipOutEdited: $tipOutEdited, ')
          ..write('rateCents: $rateCents, ')
          ..write('ruleKind: $ruleKind, ')
          ..write('ruleValue: $ruleValue, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    day,
    startMinute,
    endMinute,
    breakMinutes,
    minutes,
    cashCents,
    cardCents,
    tipInCents,
    salesCents,
    tipOutCents,
    tipOutEdited,
    rateCents,
    ruleKind,
    ruleValue,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.day == this.day &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.breakMinutes == this.breakMinutes &&
          other.minutes == this.minutes &&
          other.cashCents == this.cashCents &&
          other.cardCents == this.cardCents &&
          other.tipInCents == this.tipInCents &&
          other.salesCents == this.salesCents &&
          other.tipOutCents == this.tipOutCents &&
          other.tipOutEdited == this.tipOutEdited &&
          other.rateCents == this.rateCents &&
          other.ruleKind == this.ruleKind &&
          other.ruleValue == this.ruleValue &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<int> id;
  final Value<int> jobId;
  final Value<String> day;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<int> breakMinutes;
  final Value<int> minutes;
  final Value<int> cashCents;
  final Value<int> cardCents;
  final Value<int> tipInCents;
  final Value<int?> salesCents;
  final Value<int> tipOutCents;
  final Value<bool> tipOutEdited;
  final Value<int> rateCents;
  final Value<String> ruleKind;
  final Value<int> ruleValue;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.day = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.minutes = const Value.absent(),
    this.cashCents = const Value.absent(),
    this.cardCents = const Value.absent(),
    this.tipInCents = const Value.absent(),
    this.salesCents = const Value.absent(),
    this.tipOutCents = const Value.absent(),
    this.tipOutEdited = const Value.absent(),
    this.rateCents = const Value.absent(),
    this.ruleKind = const Value.absent(),
    this.ruleValue = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int jobId,
    required String day,
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    required int minutes,
    this.cashCents = const Value.absent(),
    this.cardCents = const Value.absent(),
    this.tipInCents = const Value.absent(),
    this.salesCents = const Value.absent(),
    this.tipOutCents = const Value.absent(),
    this.tipOutEdited = const Value.absent(),
    required int rateCents,
    this.ruleKind = const Value.absent(),
    this.ruleValue = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : jobId = Value(jobId),
       day = Value(day),
       minutes = Value(minutes),
       rateCents = Value(rateCents),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Shift> custom({
    Expression<int>? id,
    Expression<int>? jobId,
    Expression<String>? day,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<int>? breakMinutes,
    Expression<int>? minutes,
    Expression<int>? cashCents,
    Expression<int>? cardCents,
    Expression<int>? tipInCents,
    Expression<int>? salesCents,
    Expression<int>? tipOutCents,
    Expression<bool>? tipOutEdited,
    Expression<int>? rateCents,
    Expression<String>? ruleKind,
    Expression<int>? ruleValue,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (day != null) 'day': day,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (minutes != null) 'minutes': minutes,
      if (cashCents != null) 'cash_cents': cashCents,
      if (cardCents != null) 'card_cents': cardCents,
      if (tipInCents != null) 'tip_in_cents': tipInCents,
      if (salesCents != null) 'sales_cents': salesCents,
      if (tipOutCents != null) 'tip_out_cents': tipOutCents,
      if (tipOutEdited != null) 'tip_out_edited': tipOutEdited,
      if (rateCents != null) 'rate_cents': rateCents,
      if (ruleKind != null) 'rule_kind': ruleKind,
      if (ruleValue != null) 'rule_value': ruleValue,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShiftsCompanion copyWith({
    Value<int>? id,
    Value<int>? jobId,
    Value<String>? day,
    Value<int?>? startMinute,
    Value<int?>? endMinute,
    Value<int>? breakMinutes,
    Value<int>? minutes,
    Value<int>? cashCents,
    Value<int>? cardCents,
    Value<int>? tipInCents,
    Value<int?>? salesCents,
    Value<int>? tipOutCents,
    Value<bool>? tipOutEdited,
    Value<int>? rateCents,
    Value<String>? ruleKind,
    Value<int>? ruleValue,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      day: day ?? this.day,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      minutes: minutes ?? this.minutes,
      cashCents: cashCents ?? this.cashCents,
      cardCents: cardCents ?? this.cardCents,
      tipInCents: tipInCents ?? this.tipInCents,
      salesCents: salesCents ?? this.salesCents,
      tipOutCents: tipOutCents ?? this.tipOutCents,
      tipOutEdited: tipOutEdited ?? this.tipOutEdited,
      rateCents: rateCents ?? this.rateCents,
      ruleKind: ruleKind ?? this.ruleKind,
      ruleValue: ruleValue ?? this.ruleValue,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
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
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (cashCents.present) {
      map['cash_cents'] = Variable<int>(cashCents.value);
    }
    if (cardCents.present) {
      map['card_cents'] = Variable<int>(cardCents.value);
    }
    if (tipInCents.present) {
      map['tip_in_cents'] = Variable<int>(tipInCents.value);
    }
    if (salesCents.present) {
      map['sales_cents'] = Variable<int>(salesCents.value);
    }
    if (tipOutCents.present) {
      map['tip_out_cents'] = Variable<int>(tipOutCents.value);
    }
    if (tipOutEdited.present) {
      map['tip_out_edited'] = Variable<bool>(tipOutEdited.value);
    }
    if (rateCents.present) {
      map['rate_cents'] = Variable<int>(rateCents.value);
    }
    if (ruleKind.present) {
      map['rule_kind'] = Variable<String>(ruleKind.value);
    }
    if (ruleValue.present) {
      map['rule_value'] = Variable<int>(ruleValue.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
          ..write('day: $day, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('minutes: $minutes, ')
          ..write('cashCents: $cashCents, ')
          ..write('cardCents: $cardCents, ')
          ..write('tipInCents: $tipInCents, ')
          ..write('salesCents: $salesCents, ')
          ..write('tipOutCents: $tipOutCents, ')
          ..write('tipOutEdited: $tipOutEdited, ')
          ..write('rateCents: $rateCents, ')
          ..write('ruleKind: $ruleKind, ')
          ..write('ruleValue: $ruleValue, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$TipsDb extends GeneratedDatabase {
  _$TipsDb(QueryExecutor e) : super(e);
  $TipsDbManager get managers => $TipsDbManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [jobs, shifts];
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> role,
  Value<int> rateCents,
  Value<String> tipOutKind,
  Value<int> tipOutValue,
  Value<bool> tracksSales,
  Value<int> colorIndex,
  Value<bool> archived,
  required DateTime createdAt,
  Value<String?> payKind,
  Value<String?> payAnchor,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> role,
  Value<int> rateCents,
  Value<String> tipOutKind,
  Value<int> tipOutValue,
  Value<bool> tracksSales,
  Value<int> colorIndex,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<String?> payKind,
  Value<String?> payAnchor,
});

final class $$JobsTableReferences
    extends BaseReferences<_$TipsDb, $JobsTable, Job> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShiftsTable, List<Shift>> _shiftsRefsTable(
    _$TipsDb db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: 'jobs__id__shifts__job_id',
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JobsTableFilterComposer extends Composer<_$TipsDb, $JobsTable> {
  $$JobsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipOutKind => $composableBuilder(
    column: $table.tipOutKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tipOutValue => $composableBuilder(
    column: $table.tipOutValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksSales => $composableBuilder(
    column: $table.tracksSales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payKind => $composableBuilder(
    column: $table.payKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payAnchor => $composableBuilder(
    column: $table.payAnchor,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableOrderingComposer extends Composer<_$TipsDb, $JobsTable> {
  $$JobsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipOutKind => $composableBuilder(
    column: $table.tipOutKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tipOutValue => $composableBuilder(
    column: $table.tipOutValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksSales => $composableBuilder(
    column: $table.tracksSales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payKind => $composableBuilder(
    column: $table.payKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payAnchor => $composableBuilder(
    column: $table.payAnchor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JobsTableAnnotationComposer extends Composer<_$TipsDb, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<String> get tipOutKind => $composableBuilder(
    column: $table.tipOutKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tipOutValue => $composableBuilder(
    column: $table.tipOutValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksSales => $composableBuilder(
    column: $table.tracksSales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get payKind =>
      $composableBuilder(column: $table.payKind, builder: (column) => column);

  GeneratedColumn<String> get payAnchor =>
      $composableBuilder(column: $table.payAnchor, builder: (column) => column);

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$TipsDb,
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
  $$JobsTableTableManager(_$TipsDb db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<String> tipOutKind = const Value.absent(),
                Value<int> tipOutValue = const Value.absent(),
                Value<bool> tracksSales = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> payKind = const Value.absent(),
                Value<String?> payAnchor = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                name: name,
                role: role,
                rateCents: rateCents,
                tipOutKind: tipOutKind,
                tipOutValue: tipOutValue,
                tracksSales: tracksSales,
                colorIndex: colorIndex,
                archived: archived,
                createdAt: createdAt,
                payKind: payKind,
                payAnchor: payAnchor,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> role = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<String> tipOutKind = const Value.absent(),
                Value<int> tipOutValue = const Value.absent(),
                Value<bool> tracksSales = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                Value<String?> payKind = const Value.absent(),
                Value<String?> payAnchor = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                name: name,
                role: role,
                rateCents: rateCents,
                tipOutKind: tipOutKind,
                tipOutValue: tipOutValue,
                tracksSales: tracksSales,
                colorIndex: colorIndex,
                archived: archived,
                createdAt: createdAt,
                payKind: payKind,
                payAnchor: payAnchor,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTable, Job>(table),
                  $$JobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shiftsRefs) db.shifts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shiftsRefs)
                    await $_getPrefetchedDataByColumns<
                      Job,
                      $JobsTable,
                      Shift,
                      $ShiftsTable
                    >(
                      currentTable: table,
                      referencedTable: $$JobsTableReferences._shiftsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$JobsTableReferences(db, table, p0).shiftsRefs,
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
      _$TipsDb,
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
  required String day,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<int> breakMinutes,
  required int minutes,
  Value<int> cashCents,
  Value<int> cardCents,
  Value<int> tipInCents,
  Value<int?> salesCents,
  Value<int> tipOutCents,
  Value<bool> tipOutEdited,
  required int rateCents,
  Value<String> ruleKind,
  Value<int> ruleValue,
  Value<String> note,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int> jobId,
  Value<String> day,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<int> breakMinutes,
  Value<int> minutes,
  Value<int> cashCents,
  Value<int> cardCents,
  Value<int> tipInCents,
  Value<int?> salesCents,
  Value<int> tipOutCents,
  Value<bool> tipOutEdited,
  Value<int> rateCents,
  Value<String> ruleKind,
  Value<int> ruleValue,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ShiftsTableReferences
    extends BaseReferences<_$TipsDb, $ShiftsTable, Shift> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $JobsTable _jobIdTable(_$TipsDb db) =>
      db.jobs.createAlias('shifts__job_id__jobs__id');

  $$JobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<int>('job_id')!;

    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShiftsTableFilterComposer extends Composer<_$TipsDb, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
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

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashCents => $composableBuilder(
    column: $table.cashCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardCents => $composableBuilder(
    column: $table.cardCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tipInCents => $composableBuilder(
    column: $table.tipInCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get salesCents => $composableBuilder(
    column: $table.salesCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tipOutCents => $composableBuilder(
    column: $table.tipOutCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tipOutEdited => $composableBuilder(
    column: $table.tipOutEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleKind => $composableBuilder(
    column: $table.ruleKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleValue => $composableBuilder(
    column: $table.ruleValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableOrderingComposer extends Composer<_$TipsDb, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
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

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashCents => $composableBuilder(
    column: $table.cashCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardCents => $composableBuilder(
    column: $table.cardCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tipInCents => $composableBuilder(
    column: $table.tipInCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get salesCents => $composableBuilder(
    column: $table.salesCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tipOutCents => $composableBuilder(
    column: $table.tipOutCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tipOutEdited => $composableBuilder(
    column: $table.tipOutEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateCents => $composableBuilder(
    column: $table.rateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleKind => $composableBuilder(
    column: $table.ruleKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleValue => $composableBuilder(
    column: $table.ruleValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer extends Composer<_$TipsDb, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
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

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get cashCents =>
      $composableBuilder(column: $table.cashCents, builder: (column) => column);

  GeneratedColumn<int> get cardCents =>
      $composableBuilder(column: $table.cardCents, builder: (column) => column);

  GeneratedColumn<int> get tipInCents => $composableBuilder(
    column: $table.tipInCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get salesCents => $composableBuilder(
    column: $table.salesCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tipOutCents => $composableBuilder(
    column: $table.tipOutCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tipOutEdited => $composableBuilder(
    column: $table.tipOutEdited,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateCents =>
      $composableBuilder(column: $table.rateCents, builder: (column) => column);

  GeneratedColumn<String> get ruleKind =>
      $composableBuilder(column: $table.ruleKind, builder: (column) => column);

  GeneratedColumn<int> get ruleValue =>
      $composableBuilder(column: $table.ruleValue, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$TipsDb,
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
  $$ShiftsTableTableManager(_$TipsDb db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> jobId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> cashCents = const Value.absent(),
                Value<int> cardCents = const Value.absent(),
                Value<int> tipInCents = const Value.absent(),
                Value<int?> salesCents = const Value.absent(),
                Value<int> tipOutCents = const Value.absent(),
                Value<bool> tipOutEdited = const Value.absent(),
                Value<int> rateCents = const Value.absent(),
                Value<String> ruleKind = const Value.absent(),
                Value<int> ruleValue = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                jobId: jobId,
                day: day,
                startMinute: startMinute,
                endMinute: endMinute,
                breakMinutes: breakMinutes,
                minutes: minutes,
                cashCents: cashCents,
                cardCents: cardCents,
                tipInCents: tipInCents,
                salesCents: salesCents,
                tipOutCents: tipOutCents,
                tipOutEdited: tipOutEdited,
                rateCents: rateCents,
                ruleKind: ruleKind,
                ruleValue: ruleValue,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int jobId,
                required String day,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                required int minutes,
                Value<int> cashCents = const Value.absent(),
                Value<int> cardCents = const Value.absent(),
                Value<int> tipInCents = const Value.absent(),
                Value<int?> salesCents = const Value.absent(),
                Value<int> tipOutCents = const Value.absent(),
                Value<bool> tipOutEdited = const Value.absent(),
                required int rateCents,
                Value<String> ruleKind = const Value.absent(),
                Value<int> ruleValue = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ShiftsCompanion.insert(
                id: id,
                jobId: jobId,
                day: day,
                startMinute: startMinute,
                endMinute: endMinute,
                breakMinutes: breakMinutes,
                minutes: minutes,
                cashCents: cashCents,
                cardCents: cardCents,
                tipInCents: tipInCents,
                salesCents: salesCents,
                tipOutCents: tipOutCents,
                tipOutEdited: tipOutEdited,
                rateCents: rateCents,
                ruleKind: ruleKind,
                ruleValue: ruleValue,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftsTable, Shift>(table),
                  $$ShiftsTableReferences(db, table, e),
                ),
              )
              .toList(),
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
                        referencedTable: $$ShiftsTableReferences._jobIdTable(
                          db,
                        ),
                        referencedColumn: $$ShiftsTableReferences
                            ._jobIdTable(db)
                            .id,
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
      _$TipsDb,
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

class $TipsDbManager {
  final _$TipsDb _db;
  $TipsDbManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
}
