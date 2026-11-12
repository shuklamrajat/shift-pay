import 'package:drift/drift.dart';

part 'database.g.dart';

class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get rateCents => integer()();
  IntColumn get dailyLimitMin => integer().nullable()();
  IntColumn get dailyDoubleMin => integer().nullable()();
  IntColumn get weeklyLimitMin => integer().nullable()();
  IntColumn get otPct => integer().withDefault(const Constant(150))();
  IntColumn get doublePct => integer().withDefault(const Constant(200))();
  IntColumn get weekStartsOn => integer().withDefault(const Constant(DateTime.monday))();
  IntColumn get workdayStartMinute => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer().references(Jobs, #id)();
  DateTimeColumn get start => dateTime()();

  /// Null while clocked in.
  DateTimeColumn get end => dateTime().nullable()();
  IntColumn get unpaidBreakMin => integer().withDefault(const Constant(0))();

  /// Rate at the time the shift was logged, so raises don't reprice history.
  IntColumn get rateCents => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Jobs, Shifts])
class HoursDb extends _$HoursDb {
  HoursDb(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
      );
}
