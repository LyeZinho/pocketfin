import 'package:drift/drift.dart';

import '../../core/constants/categories.dart';
import '../local/app_database.dart';
import '../models/imported_transaction.dart';

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
            id: const Value(1),
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

  /// Inserts imported entries, skipping exact duplicates already in the
  /// database. Returns how many rows were actually inserted.
  Future<int> importEntries(List<ImportedTransaction> entries) {
    if (entries.isEmpty) return Future.value(0);

    return _db.transaction(() async {
      final existing = await _db.select(_db.transactionEntries).get();
      final seen = existing
          .map(
            (entry) => _dedupeKey(
              title: entry.title,
              category: entry.category,
              type: entry.type,
              amountCents: entry.amountCents,
              occurredAt: entry.occurredAt,
            ),
          )
          .toSet();

      final companions = <TransactionEntriesCompanion>[];
      for (final entry in entries) {
        final key = _dedupeKey(
          title: entry.title,
          category: entry.category.name,
          type: entry.type.name,
          amountCents: entry.amountCents,
          occurredAt: entry.occurredAt,
        );
        if (!seen.add(key)) continue;
        companions.add(
          TransactionEntriesCompanion.insert(
            title: entry.title,
            category: entry.category.name,
            type: entry.type.name,
            amountCents: entry.amountCents,
            note: Value(entry.note),
            occurredAt: entry.occurredAt,
          ),
        );
      }

      if (companions.isEmpty) return 0;
      await _db.batch((batch) {
        batch.insertAll(_db.transactionEntries, companions);
      });
      return companions.length;
    });
  }

  Future<void> clear() => _db.delete(_db.transactionEntries).go();

  String _dedupeKey({
    required String title,
    required String category,
    required String type,
    required int amountCents,
    required DateTime occurredAt,
  }) {
    return '${title.trim().toLowerCase()}|$category|$type|$amountCents|'
        '${occurredAt.toIso8601String()}';
  }
}
