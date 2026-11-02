import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketfin/core/constants/categories.dart';
import 'package:pocketfin/data/local/app_database.dart';
import 'package:pocketfin/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase database;
  late TransactionRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TransactionRepository(database);
  });

  tearDown(() => database.close());

  test('persists transactions and streams them back', () async {
    await repository.addEntry(
      title: 'Coffee',
      category: TxCategory.food,
      type: TxType.expense,
      amountCents: 450,
      occurredAt: DateTime(2026, 11, 2, 8),
    );

    final entries = await repository.watchAll().first;
    expect(entries, hasLength(1));
    expect(entries.single.title, 'Coffee');
    expect(entries.single.amountCents, 450);
    expect(entries.single.category, TxCategory.food.name);
  });

  test('stores the monthly budget', () async {
    expect(await repository.watchMonthlyBudget().first, 125000);

    await repository.setMonthlyBudget(100000);
    expect(await repository.watchMonthlyBudget().first, 100000);
  });

  test('deletes entries', () async {
    final id = await repository.addEntry(
      title: 'Metro',
      category: TxCategory.transit,
      type: TxType.expense,
      amountCents: 290,
      occurredAt: DateTime(2026, 11, 2, 8),
    );

    await repository.deleteEntry(id);
    expect(await repository.watchAll().first, isEmpty);
  });
}
