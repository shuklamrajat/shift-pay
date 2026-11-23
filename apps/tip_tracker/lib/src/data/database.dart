import 'package:drift/drift.dart';

part 'database.g.dart';

class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// server, bartender, delivery, other.
  TextColumn get role => text().withDefault(const Constant('server'))();
  IntColumn get rateCents => integer().withDefault(const Constant(0))();

  /// TipOutKind name.
  TextColumn get tipOutKind => text().withDefault(const Constant('none'))();

  /// Basis points for % rules, cents for flat.
  IntColumn get tipOutValue => integer().withDefault(const Constant(0))();
  BoolColumn get tracksSales => boolean().withDefault(const Constant(false))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer().references(Jobs, #id)();

  /// "YYYY-MM-DD", the day the shift started.
  TextColumn get day => text().withLength(min: 10, max: 10)();

  /// Minute of the day, or null when only hours were typed.
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();
  IntColumn get breakMinutes => integer().withDefault(const Constant(0))();

  /// Paid minutes worked (end - start - break, or the typed hours).
  IntColumn get minutes => integer()();
  IntColumn get cashCents => integer().withDefault(const Constant(0))();
  IntColumn get cardCents => integer().withDefault(const Constant(0))();
  IntColumn get tipInCents => integer().withDefault(const Constant(0))();
  IntColumn get salesCents => integer().nullable()();

  /// The tip-out actually paid that night.
  IntColumn get tipOutCents => integer().withDefault(const Constant(0))();
  BoolColumn get tipOutEdited => boolean().withDefault(const Constant(false))();

  /// Wage and rule in force when the shift was saved, so a raise or a new
  /// rule never reprices old nights.
  IntColumn get rateCents => integer()();
  TextColumn get ruleKind => text().withDefault(const Constant('none'))();
  IntColumn get ruleValue => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [];
}

/// Called before any schema upgrade runs, with the old version, so the app
/// can snapshot every row first. An update must never be able to lose data.
typedef BeforeUpgrade = Future<void> Function(TipsDb db, int fromVersion);

@DriftDatabase(tables: [Jobs, Shifts])
class TipsDb extends _$TipsDb {
  TipsDb(super.e, {this.beforeUpgrade});

  final BeforeUpgrade? beforeUpgrade;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX IF NOT EXISTS shifts_day ON shifts (day)');
      await customStatement('CREATE INDEX IF NOT EXISTS shifts_job ON shifts (job_id)');
    },
    onUpgrade: (m, from, to) async {
      await beforeUpgrade?.call(this, from);
      // Future schema steps go here, each one additive.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// SQLite's own checks. Empty list means healthy.
  Future<List<String>> healthProblems() async {
    final problems = <String>[];
    final integrity = await customSelect('PRAGMA integrity_check').get();
    final first = integrity.isEmpty ? 'ok' : integrity.first.data.values.first.toString();
    if (first != 'ok') problems.add('integrity: $first');
    final fk = await customSelect('PRAGMA foreign_key_check').get();
    if (fk.isNotEmpty) problems.add('${fk.length} shift(s) point to a missing job');
    return problems;
  }
}
