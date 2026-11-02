import 'package:intl/intl.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_theme.dart';
import '../data/local/app_database.dart';

enum StatsPeriod { week, month, year }

class HomeSummary {
  const HomeSummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.budgetCents,
  });

  final int incomeCents;
  final int expenseCents;
  final int budgetCents;

  int get balanceCents => incomeCents - expenseCents;
  int get remainingCents => budgetCents - expenseCents;
  double get budgetRatio =>
      budgetCents <= 0 ? 0 : (expenseCents / budgetCents).clamp(0, 1.5);
  int get budgetPercent => (budgetRatio * 100).round();
}

class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.cents,
    required this.percent,
  });

  final TxCategory category;
  final int cents;
  final int percent;
}

class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.cents,
    required this.label,
  });

  final DateTime date;
  final int cents;
  final String label;
}

enum InsightTone { purple, lime, coral }

class Insight {
  const Insight({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final InsightTone tone;
}

abstract final class Analytics {
  static bool isExpense(TransactionEntry entry) =>
      entry.type == TxType.expense.name;
  static bool isIncome(TransactionEntry entry) =>
      entry.type == TxType.income.name;

  static List<TransactionEntry> forMonth(
    List<TransactionEntry> entries,
    DateTime month,
  ) {
    return entries
        .where((entry) => isSameMonthForAnalytics(entry.occurredAt, month))
        .toList();
  }

  static bool isSameMonthForAnalytics(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static HomeSummary summarize(
    List<TransactionEntry> entries, {
    required int budgetCents,
  }) {
    var income = 0;
    var expense = 0;
    for (final entry in entries) {
      if (isIncome(entry)) {
        income += entry.amountCents;
      } else if (isExpense(entry)) {
        expense += entry.amountCents;
      }
    }
    return HomeSummary(
      incomeCents: income,
      expenseCents: expense,
      budgetCents: budgetCents,
    );
  }

  static List<CategorySlice> categoryBreakdown(
    List<TransactionEntry> entries,
  ) {
    final totals = <TxCategory, int>{};
    for (final entry in entries) {
      if (!isExpense(entry)) continue;
      final category = TxCategory.fromName(entry.category);
      totals[category] = (totals[category] ?? 0) + entry.amountCents;
    }
    if (totals.isEmpty) return const [];

    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    var slices = totals.entries
        .map(
          (entry) => CategorySlice(
            category: entry.key,
            cents: entry.value,
            percent: total == 0 ? 0 : (entry.value / total * 100).round(),
          ),
        )
        .toList()
      ..sort((a, b) => b.cents.compareTo(a.cents));

    if (slices.length > 3) {
      final otherCents = slices
          .skip(3)
          .fold<int>(0, (sum, slice) => sum + slice.cents);
      slices = [
        ...slices.take(3),
        CategorySlice(
          category: TxCategory.other,
          cents: otherCents,
          percent: total == 0 ? 0 : (otherCents / total * 100).round(),
        ),
      ];
    }

    final rounded = slices.fold<int>(0, (sum, slice) => sum + slice.percent);
    if (slices.isNotEmpty && rounded != 100) {
      final last = slices.removeLast();
      slices.add(
        CategorySlice(
          category: last.category,
          cents: last.cents,
          percent: (last.percent + (100 - rounded)).clamp(0, 100),
        ),
      );
    }
    return slices;
  }

  static List<DailyPoint> dailySeries(
    List<TransactionEntry> entries,
    StatsPeriod period,
    DateTime now,
  ) {
    final expenses = entries.where(isExpense).toList();
    switch (period) {
      case StatsPeriod.week:
        final today = DateTime(now.year, now.month, now.day);
        final start = today.subtract(Duration(days: now.weekday - 1));
        return List.generate(7, (index) {
          final day = start.add(Duration(days: index));
          final cents = expenses
              .where((entry) => _isSameDay(entry.occurredAt, day))
              .fold<int>(0, (sum, entry) => sum + entry.amountCents);
          return DailyPoint(
            date: day,
            cents: cents,
            label: DateFormat('E', 'en_US').format(day).substring(0, 1),
          );
        });
      case StatsPeriod.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final daily = List.generate(daysInMonth, (index) {
          final day = DateTime(now.year, now.month, index + 1);
          final cents = expenses
              .where((entry) => _isSameDay(entry.occurredAt, day))
              .fold<int>(0, (sum, entry) => sum + entry.amountCents);
          final showLabel = index == 0 ||
              (index + 1) % 5 == 0 ||
              index + 1 == daysInMonth;
          return DailyPoint(
            date: day,
            cents: cents,
            label: showLabel ? '${index + 1}' : '',
          );
        });
        return daily;
      case StatsPeriod.year:
        return List.generate(12, (index) {
          final month = DateTime(now.year, index + 1);
          final cents = expenses
              .where((entry) => isSameMonthForAnalytics(entry.occurredAt, month))
              .fold<int>(0, (sum, entry) => sum + entry.amountCents);
          return DailyPoint(
            date: month,
            cents: cents,
            label: DateFormat('MMM', 'en_US').format(month).substring(0, 1),
          );
        });
    }
  }

  static int averageDailySpend(
    List<TransactionEntry> entries,
    StatsPeriod period,
    DateTime now,
  ) {
    final expenses = entries.where(isExpense);
    final total = expenses.fold<int>(0, (sum, entry) => sum + entry.amountCents);
    final days = switch (period) {
      StatsPeriod.week => 7,
      StatsPeriod.month => _isSameMonth(now, DateTime(now.year, now.month))
          ? now.day
          : DateTime(now.year, now.month + 1, 0).day,
      StatsPeriod.year => now.difference(DateTime(now.year)).inDays + 1,
    };
    return days <= 0 ? 0 : (total / days).round();
  }

  static List<Insight> buildInsights(
    List<TransactionEntry> entries,
    DateTime now,
  ) {
    final insights = <Insight>[];
    final expenses = entries.where(isExpense).toList();

    final weekdayInsight = _weekdayInsight(expenses, now);
    if (weekdayInsight != null) insights.add(weekdayInsight);

    final savingsInsight = _savingsInsight(entries, now);
    if (savingsInsight != null) insights.add(savingsInsight);

    final subscriptionInsight = _subscriptionInsight(expenses, now);
    if (subscriptionInsight != null) insights.add(subscriptionInsight);

    return insights;
  }

  static Insight? _weekdayInsight(
    List<TransactionEntry> expenses,
    DateTime now,
  ) {
    final start = now.subtract(const Duration(days: 56));
    final recent =
        expenses.where((entry) => entry.occurredAt.isAfter(start)).toList();
    if (recent.isEmpty) return null;

    final totals = List<int>.filled(8, 0);
    for (final entry in recent) {
      totals[entry.occurredAt.weekday] += entry.amountCents;
    }

    var busiest = 1;
    for (var day = 2; day <= 7; day++) {
      if (totals[day] > totals[busiest]) busiest = day;
    }
    if (totals[busiest] == 0) return null;

    var occurrences = 0;
    for (var day = start;
        day.isBefore(now.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      if (day.weekday == busiest) occurrences++;
    }
    occurrences = occurrences == 0 ? 1 : occurrences;

    final averageCents = totals[busiest] ~/ occurrences;
    final capDollars =
        ((averageCents / 100 * 0.75) / 5).ceil().clamp(5, 100000) * 5;
    final savingsDollars =
        ((averageCents - capDollars * 100) * 4.3 / 100).round().clamp(0, 100000);
    final weekday = weekdayName(busiest);

    return Insight(
      title: 'You spend most on ${weekday}s.',
      body: savingsDollars > 0
          ? 'Set a \$$capDollars $weekday cap and you could keep about \$$savingsDollars a month.'
          : 'Set a \$$capDollars $weekday cap to keep your week on track.',
      tone: InsightTone.purple,
    );
  }

  static Insight? _savingsInsight(
    List<TransactionEntry> entries,
    DateTime now,
  ) {
    final current = forMonth(entries, now);
    final summary = summarize(current, budgetCents: 0);
    if (summary.incomeCents <= 0) return null;

    final rate =
        ((summary.incomeCents - summary.expenseCents) / summary.incomeCents * 100)
            .round();

    final previousMonth = DateTime(now.year, now.month - 1);
    final previous = summarize(
      forMonth(entries, previousMonth),
      budgetCents: 0,
    );

    String body = 'Of every dollar that came in this month';
    if (previous.incomeCents > 0) {
      final previousRate = ((previous.incomeCents - previous.expenseCents) /
              previous.incomeCents *
              100)
          .round();
      final delta = rate - previousRate;
      body = delta >= 0
          ? 'Up $delta points this month'
          : 'Down ${delta.abs()} points this month';
    }

    return Insight(
      title: 'Savings rate $rate%',
      body: body,
      tone: InsightTone.lime,
    );
  }

  static Insight? _subscriptionInsight(
    List<TransactionEntry> expenses,
    DateTime now,
  ) {
    final cutoff = DateTime(now.year, now.month - 3, now.day);
    final bills = expenses.where((entry) {
      return TxCategory.fromName(entry.category) == TxCategory.bills &&
          entry.occurredAt.isAfter(cutoff);
    });

    final monthsByTitle = <String, Set<String>>{};
    final latestByTitle = <String, TransactionEntry>{};
    for (final entry in bills) {
      final key = entry.title.trim().toLowerCase();
      final monthKey = '${entry.occurredAt.year}-${entry.occurredAt.month}';
      (monthsByTitle[key] ??= <String>{}).add(monthKey);
      final latest = latestByTitle[key];
      if (latest == null || entry.occurredAt.isAfter(latest.occurredAt)) {
        latestByTitle[key] = entry;
      }
    }

    final recurring = monthsByTitle.entries
        .where((entry) => entry.value.length >= 2)
        .map((entry) => latestByTitle[entry.key]!)
        .toList();
    if (recurring.isEmpty) return null;

    final monthlyCents =
        recurring.fold<int>(0, (sum, entry) => sum + entry.amountCents);
    return Insight(
      title:
          '${recurring.length} subscription${recurring.length == 1 ? '' : 's'}',
      body: 'Review ${formatMoney(monthlyCents)} monthly',
      tone: InsightTone.coral,
    );
  }

  static String statsTip(List<TransactionEntry> entries, DateTime month) {
    final current = categoryBreakdown(forMonth(entries, month));
    if (current.isEmpty) {
      return 'Add a few expenses to unlock a tip for this period.';
    }

    final top = current.first;
    final previousMonth = DateTime(month.year, month.month - 1);
    final previous = categoryBreakdown(forMonth(entries, previousMonth))
        .where((slice) => slice.category == top.category)
        .toList();
    final suggestion = _suggestion(top.category);

    if (previous.isNotEmpty && previous.first.cents > 0) {
      final delta =
          ((top.cents - previous.first.cents) / previous.first.cents * 100)
              .round();
      final saving = (top.cents * 0.1 / 100).round();
      if (delta == 0) {
        return '${top.category.label} is flat versus last month. '
            '$suggestion could save about \$$saving.';
      }
      final direction = delta > 0 ? 'above' : 'below';
      return '${top.category.label} is ${delta.abs()}% $direction last month. '
          '$suggestion could save about \$$saving.';
    }

    return '${top.category.label} is your top category at '
        '${formatMoney(top.cents)} this month. $suggestion.';
  }

  static String _suggestion(TxCategory category) {
    return switch (category) {
      TxCategory.food => 'Cooking twice more a week',
      TxCategory.transit => 'Combining a few trips',
      TxCategory.home => 'Reviewing recurring home costs',
      TxCategory.fun => 'Setting a weekend cap',
      TxCategory.health => 'Comparing pharmacy prices',
      TxCategory.bills => 'Auditing your subscriptions',
      TxCategory.salary => 'Automating a transfer to savings',
      TxCategory.other => 'Reviewing smaller purchases',
    };
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
