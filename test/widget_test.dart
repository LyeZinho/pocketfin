import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketfin/app.dart';
import 'package:pocketfin/core/constants/categories.dart';
import 'package:pocketfin/data/local/app_database.dart';
import 'package:pocketfin/data/models/imported_transaction.dart';
import 'package:pocketfin/data/repositories/transaction_repository.dart';
import 'package:pocketfin/logic/providers.dart';

class _FakeRepository implements TransactionRepository {
  final saved = <TransactionEntry>[];

  @override
  Stream<List<TransactionEntry>> watchAll() => Stream.value(const []);

  @override
  Stream<int> watchMonthlyBudget() => Stream.value(125000);

  @override
  Future<int> setMonthlyBudget(int cents) async => cents;

  @override
  Future<int> addEntry({
    required String title,
    required TxCategory category,
    required TxType type,
    required int amountCents,
    String? note,
    required DateTime occurredAt,
  }) async {
    final entry = TransactionEntry(
      id: saved.length + 1,
      title: title,
      category: category.name,
      type: type.name,
      amountCents: amountCents,
      note: note,
      occurredAt: occurredAt,
    );
    saved.add(entry);
    return entry.id;
  }

  @override
  Future<int> importEntries(List<ImportedTransaction> entries) async => 0;

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Future<void> clear() async {}
}

final _entries = [
  TransactionEntry(
    id: 1,
    title: 'Salary',
    category: TxCategory.salary.name,
    type: TxType.income.name,
    amountCents: 320000,
    occurredAt: DateTime(2026, 11, 2, 9),
  ),
  TransactionEntry(
    id: 2,
    title: 'Groceries',
    category: TxCategory.food.name,
    type: TxType.expense.name,
    amountCents: 4230,
    occurredAt: DateTime(2026, 11, 2, 10),
  ),
];

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        transactionsProvider.overrideWithValue(AsyncData(_entries)),
        monthlyBudgetProvider.overrideWithValue(const AsyncData(125000)),
        nowProvider.overrideWithValue(DateTime(2026, 11, 2, 12)),
      ],
      child: const PocketFinApp(),
    ),
  );
  await _pumpFrames(tester);
}

void main() {
  testWidgets('home renders the summary and today entries', (tester) async {
    await _pumpApp(tester, _FakeRepository());

    expect(find.text('PocketFin'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text(r'+$3,200'), findsOneWidget);
    expect(find.text(r'-$42.30'), findsOneWidget);
  });

  testWidgets('coach screen offers the excel import action', (tester) async {
    await _pumpApp(tester, _FakeRepository());

    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await _pumpFrames(tester);
    await tester.scrollUntilVisible(
      find.text('Import from Excel'),
      320,
    );

    expect(find.text('Import from Excel'), findsOneWidget);
    expect(find.text('Restore a PocketFin .xlsx backup'), findsOneWidget);
  });

  testWidgets('add entry saves a transaction', (tester) async {
    final repository = _FakeRepository();
    await _pumpApp(tester, repository);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await _pumpFrames(tester);
    expect(find.text('New entry'), findsOneWidget);

    for (final key in ['2', '4', '.', '5', '0']) {
      await tester.tap(find.text(key).last);
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Save expense'));
    await tester.pump();
    await tester.tap(find.text('Save expense'));
    await _pumpFrames(tester);

    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.amountCents, 2450);
    expect(repository.saved.single.type, TxType.expense.name);
    expect(find.text('New entry'), findsNothing);
  });
}
