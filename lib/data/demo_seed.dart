import '../core/constants/categories.dart';
import '../data/repositories/transaction_repository.dart';

/// Seeds a month of realistic data for previewing the UI.
/// Enable with: flutter run --dart-define=SEED_DEMO=true
Future<void> seedDemoData(
  TransactionRepository repository,
  DateTime now,
) async {
  await repository.setMonthlyBudget(125000);

  Future<void> add({
    required String title,
    required TxCategory category,
    required TxType type,
    required int cents,
    required DateTime at,
    String? note,
  }) {
    return repository.addEntry(
      title: title,
      category: category,
      type: type,
      amountCents: cents,
      note: note,
      occurredAt: at,
    );
  }

  final today = DateTime(now.year, now.month, now.day);

  // Today, matching the Home mock.
  await add(
    title: 'Groceries',
    category: TxCategory.food,
    type: TxType.expense,
    cents: 4230,
    at: today.add(const Duration(hours: 10, minutes: 24)),
  );
  await add(
    title: 'Salary',
    category: TxCategory.salary,
    type: TxType.income,
    cents: 320000,
    at: today.add(const Duration(hours: 9)),
    note: 'Monthly payroll',
  );
  await add(
    title: 'Metro',
    category: TxCategory.transit,
    type: TxType.expense,
    cents: 290,
    at: today.add(const Duration(hours: 8, minutes: 10)),
  );
  await add(
    title: 'Coffee',
    category: TxCategory.food,
    type: TxType.expense,
    cents: 450,
    at: today.add(const Duration(hours: 7, minutes: 45)),
  );

  // Earlier in the current month.
  final first = DateTime(now.year, now.month, 1);
  await add(
    title: 'Rent',
    category: TxCategory.home,
    type: TxType.expense,
    cents: 42000,
    at: first.add(const Duration(hours: 9)),
  );
  await add(
    title: 'Weekly shop',
    category: TxCategory.food,
    type: TxType.expense,
    cents: 6540,
    at: first.add(const Duration(hours: 18)),
  );
  await add(
    title: 'Dinner out',
    category: TxCategory.fun,
    type: TxType.expense,
    cents: 20000,
    at: first.add(const Duration(hours: 21)),
  );
  await add(
    title: 'Pharmacy',
    category: TxCategory.health,
    type: TxType.expense,
    cents: 1290,
    at: first.add(const Duration(hours: 12)),
  );
  await add(
    title: 'Transit pass',
    category: TxCategory.transit,
    type: TxType.expense,
    cents: 2200,
    at: first.add(const Duration(hours: 8)),
  );
  await add(
    title: 'Netflix',
    category: TxCategory.bills,
    type: TxType.expense,
    cents: 1599,
    at: first.add(const Duration(hours: 6)),
  );
  await add(
    title: 'Spotify',
    category: TxCategory.bills,
    type: TxType.expense,
    cents: 1099,
    at: first.add(const Duration(hours: 6, minutes: 5)),
  );
  await add(
    title: 'iCloud',
    category: TxCategory.bills,
    type: TxType.expense,
    cents: 299,
    at: first.add(const Duration(hours: 6, minutes: 10)),
  );

  // The last two months, so the coach can compare and detect subscriptions.
  for (var monthsAgo = 1; monthsAgo <= 2; monthsAgo++) {
    final month = DateTime(now.year, now.month - monthsAgo, 1);
    await add(
      title: 'Salary',
      category: TxCategory.salary,
      type: TxType.income,
      cents: 320000,
      at: month.add(const Duration(hours: 9)),
    );
    await add(
      title: 'Rent',
      category: TxCategory.home,
      type: TxType.expense,
      cents: 42000,
      at: month.add(const Duration(hours: 9)),
    );
    await add(
      title: 'Netflix',
      category: TxCategory.bills,
      type: TxType.expense,
      cents: 1599,
      at: month.add(const Duration(hours: 6)),
    );
    await add(
      title: 'Spotify',
      category: TxCategory.bills,
      type: TxType.expense,
      cents: 1099,
      at: month.add(const Duration(hours: 6, minutes: 5)),
    );
    await add(
      title: 'iCloud',
      category: TxCategory.bills,
      type: TxType.expense,
      cents: 299,
      at: month.add(const Duration(hours: 6, minutes: 10)),
    );
    await add(
      title: 'Groceries',
      category: TxCategory.food,
      type: TxType.expense,
      cents: 18000,
      at: month.add(const Duration(days: 12, hours: 18)),
    );
    await add(
      title: 'Night out',
      category: TxCategory.fun,
      type: TxType.expense,
      cents: 9000,
      at: month.add(const Duration(days: 20, hours: 21)),
    );
  }

  // A few Fridays, to power the "you spend most on Fridays" insight.
  for (var weeksAgo = 1; weeksAgo <= 4; weeksAgo++) {
    var friday = today.subtract(Duration(days: weeksAgo * 7));
    friday = friday.subtract(Duration(days: friday.weekday - DateTime.friday));
    await add(
      title: 'Friday dinner',
      category: TxCategory.fun,
      type: TxType.expense,
      cents: 5800 + weeksAgo * 300,
      at: DateTime(friday.year, friday.month, friday.day, 20, 30),
    );
  }
}
