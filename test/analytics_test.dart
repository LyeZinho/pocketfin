import 'package:flutter_test/flutter_test.dart';
import 'package:pocketfin/core/constants/categories.dart';
import 'package:pocketfin/data/local/app_database.dart';
import 'package:pocketfin/logic/analytics.dart';

TransactionEntry entry({
  required int cents,
  TxType type = TxType.expense,
  TxCategory category = TxCategory.food,
  DateTime? at,
  String title = 'Test',
}) {
  return TransactionEntry(
    id: 1,
    title: title,
    category: category.name,
    type: type.name,
    amountCents: cents,
    occurredAt: at ?? DateTime(2026, 11, 2),
  );
}

void main() {
  group('summarize', () {
    test('splits income and expenses and derives the balance', () {
      final summary = Analytics.summarize(
        [
          entry(cents: 320000, type: TxType.income, category: TxCategory.salary),
          entry(cents: 4230),
          entry(cents: 290, category: TxCategory.transit),
        ],
        budgetCents: 125000,
      );

      expect(summary.incomeCents, 320000);
      expect(summary.expenseCents, 4520);
      expect(summary.balanceCents, 315480);
      expect(summary.budgetPercent, 4);
      expect(summary.remainingCents, 120480);
    });
  });

  group('categoryBreakdown', () {
    test('groups expenses and rounds percentages to 100', () {
      final slices = Analytics.categoryBreakdown([
        entry(cents: 6000),
        entry(cents: 4000, category: TxCategory.home),
      ]);

      expect(slices.length, 2);
      expect(slices.first.category, TxCategory.food);
      expect(slices.first.percent, 60);
      expect(slices.last.percent, 40);
    });

    test('folds everything past the top three into Other', () {
      final slices = Analytics.categoryBreakdown([
        entry(cents: 5000, category: TxCategory.food),
        entry(cents: 3000, category: TxCategory.home),
        entry(cents: 1500, category: TxCategory.fun),
        entry(cents: 500, category: TxCategory.health),
      ]);

      expect(slices.length, 4);
      expect(slices.last.category, TxCategory.other);
      expect(slices.last.cents, 500);
      expect(slices.fold<int>(0, (sum, slice) => sum + slice.percent), 100);
    });
  });

  group('insights', () {
    test('finds the most expensive weekday', () {
      final entries = <TransactionEntry>[];
      for (var week = 0; week < 4; week++) {
        final friday = DateTime(2026, 10, 30).subtract(
          Duration(days: week * 7),
        );
        entries.add(entry(cents: 10000, at: friday));
      }

      final insights = Analytics.buildInsights(
        entries,
        DateTime(2026, 11, 2),
      );

      expect(insights.first.title, 'You spend most on Fridays.');
      expect(insights.first.tone, InsightTone.purple);
    });

    test('computes the savings rate against the previous month', () {
      final entries = [
        entry(
          cents: 100000,
          type: TxType.income,
          category: TxCategory.salary,
          at: DateTime(2026, 11, 1),
        ),
        entry(cents: 76000, at: DateTime(2026, 11, 1)),
        entry(
          cents: 100000,
          type: TxType.income,
          category: TxCategory.salary,
          at: DateTime(2026, 10, 1),
        ),
        entry(cents: 79000, at: DateTime(2026, 10, 1)),
      ];

      final insights = Analytics.buildInsights(
        entries,
        DateTime(2026, 11, 2),
      );
      final savings = insights.firstWhere(
        (insight) => insight.title.startsWith('Savings rate'),
      );

      expect(savings.title, 'Savings rate 24%');
      expect(savings.body, 'Up 3 points this month');
    });

    test('detects recurring bills across months', () {
      final entries = [
        entry(
          cents: 1599,
          category: TxCategory.bills,
          at: DateTime(2026, 10, 1),
          title: 'Netflix',
        ),
        entry(
          cents: 1599,
          category: TxCategory.bills,
          at: DateTime(2026, 11, 1),
          title: 'Netflix',
        ),
      ];

      final insights = Analytics.buildInsights(
        entries,
        DateTime(2026, 11, 2),
      );
      final subscriptions = insights.firstWhere(
        (insight) => insight.title.contains('subscription'),
      );

      expect(subscriptions.title, '1 subscription');
      expect(subscriptions.body, 'Review \$15.99 monthly');
    });
  });

  group('statsTip', () {
    test('compares the top category with the previous month', () {
      final tip = Analytics.statsTip(
        [
          entry(cents: 11000, at: DateTime(2026, 11, 1)),
          entry(cents: 10000, at: DateTime(2026, 10, 1)),
        ],
        DateTime(2026, 11, 2),
      );

      expect(tip, contains('Food is 10% above last month'));
      expect(tip, contains('could save about \$11'));
    });
  });
}
