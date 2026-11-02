import 'package:drift/drift.dart';

import '../../core/constants/categories.dart';
import '../local/app_database.dart';

class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Stream<List<TransactionEntry>> watchAll() {
    final query = _db.select(_db.transactionEntries)
      ..orderBy([
        (t) => OrderingTerm.desc(t.occurredAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Stream<int> watchMonthlyBudget() {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.id.equals(1));
    return query.watchSingleOrNull().map(
          (row) => row?.monthlyBudgetCents ?? 125000,
        );
  }

  Future<int> setMonthlyBudget(int cents) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            monthlyBudgetCents: Value(cents),
          ),
        );
    return cents;
  }

  Future<int> addEntry({
    required String title,
    required TxCategory category,
    required TxType type,
    required int amountCents,
    String? note,
    required DateTime occurredAt,
  }) {
    return _db.into(_db.transactionEntries).insert(
          TransactionEntriesCompanion.insert(
            title: title,
            category: category.name,
            type: type.name,
            amountCents: amountCents,
            note: Value(note),
            occurredAt: occurredAt,
          ),
        );
  }

  Future<void> deleteEntry(int id) {
    return (_db.delete(_db.transactionEntries)..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> clear() => _db.delete(_db.transactionEntries).go();
}
