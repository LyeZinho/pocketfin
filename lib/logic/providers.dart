import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/services/export_service.dart';
import 'analytics.dart';

final nowProvider = Provider<DateTime>((ref) => DateTime.now());

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final transactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  return ref.watch(repositoryProvider).watchAll();
});

final monthlyBudgetProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchMonthlyBudget();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = ref.watch(nowProvider);
    return DateTime(now.year, now.month);
  }

  void previous() {
    state = DateTime(state.year, state.month - 1);
  }

  void next() {
    state = DateTime(state.year, state.month + 1);
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

class StatsPeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.month;

  void select(StatsPeriod period) => state = period;
}

final statsPeriodProvider =
    NotifierProvider<StatsPeriodNotifier, StatsPeriod>(StatsPeriodNotifier.new);

final monthEntriesProvider =
    Provider<AsyncValue<List<TransactionEntry>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(transactionsProvider)
      .whenData((entries) => Analytics.forMonth(entries, month));
});

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  final entries = ref.watch(monthEntriesProvider);
  final budget = ref.watch(monthlyBudgetProvider);
  return entries.when(
    data: (list) => budget.when(
      data: (value) => AsyncData(
        Analytics.summarize(list, budgetCents: value),
      ),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
      loading: () => const AsyncLoading(),
    ),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    loading: () => const AsyncLoading(),
  );
});

class StatsData {
  const StatsData({
    required this.slices,
    required this.totalCents,
    required this.points,
    required this.averageCents,
    required this.tip,
  });

  final List<CategorySlice> slices;
  final int totalCents;
  final List<DailyPoint> points;
  final int averageCents;
  final String tip;
}

final statsDataProvider = Provider<AsyncValue<StatsData>>((ref) {
  final period = ref.watch(statsPeriodProvider);
  final now = ref.watch(nowProvider);
  final month = ref.watch(selectedMonthProvider);

  return ref.watch(transactionsProvider).whenData((entries) {
    final scoped = switch (period) {
      StatsPeriod.week => entries.where((entry) {
          final start = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final end = start.add(const Duration(days: 6));
          return !entry.occurredAt.isBefore(start) &&
              !entry.occurredAt.isAfter(end.add(const Duration(days: 1)));
        }).toList(),
      StatsPeriod.month => Analytics.forMonth(entries, month),
      StatsPeriod.year =>
        entries.where((entry) => entry.occurredAt.year == now.year).toList(),
    };

    final slices = Analytics.categoryBreakdown(scoped);
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.cents);
    final points = Analytics.dailySeries(entries, period, now);

    return StatsData(
      slices: slices,
      totalCents: total,
      points: points,
      averageCents: Analytics.averageDailySpend(scoped, period, now),
      tip: Analytics.statsTip(entries, month),
    );
  });
});

final insightsProvider = Provider<AsyncValue<List<Insight>>>((ref) {
  final now = ref.watch(nowProvider);
  return ref
      .watch(transactionsProvider)
      .whenData((entries) => Analytics.buildInsights(entries, now));
});
