import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class TransactionEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get category => text()();
  TextColumn get type => text()();
  IntColumn get amountCents => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get monthlyBudgetCents =>
      integer().withDefault(const Constant(125000))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TransactionEntries, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'pocketfin'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
