import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../../data/local/app_database.dart';
import '../../logic/analytics.dart';
import '../../logic/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);
    final month = ref.watch(selectedMonthProvider);
    final entries = ref.watch(monthEntriesProvider);
    final now = ref.watch(nowProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScaffoldBody(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
              children: [
                _HomeHeader(month: month),
                const SizedBox(height: 22),
                summary.when(
                  data: (value) => _BalanceCard(summary: value),
                  loading: () => const _CardLoader(height: 232),
                  error: (error, stackTrace) => _ErrorCard(),
                ),
                const SizedBox(height: 16),
                summary.when(
                  data: (value) => _BudgetCard(summary: value),
                  loading: () => const _CardLoader(height: 116),
                  error: (error, stackTrace) => _ErrorCard(),
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'Today',
                  action: 'See all',
                  onAction: () => _showMonthEntries(context, entries.value ?? []),
                ),
                entries.when(
                  data: (list) {
                    final today = list
                        .where((entry) => isSameDay(entry.occurredAt, now))
                        .toList();
                    if (today.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Nothing logged today',
                        body: 'Tap the plus button to record your first entry.',
                      );
                    }
                    return Column(
                      children: [
                        for (final entry in today) TransactionTile(entry: entry),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    ),
                  ),
                  error: (error, stackTrace) => const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load entries',
                    body: 'Close and reopen the app to try again.',
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 12,
              child: AddEntryButton(onTap: () => context.push('/add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthEntries(
    BuildContext context,
    List<TransactionEntry> entries,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final sorted = [...entries]
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final children = <Widget>[];
        String? currentDay;
        for (final entry in sorted) {
          final day = formatDayLabel(entry.occurredAt);
          if (day != currentDay) {
            currentDay = day;
            children.add(
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 4),
                child: Text(
                  day,
                  style: AppText.data(
                    12,
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          }
          children.add(TransactionTile(entry: entry));
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              children: [
                Text('This month', style: AppText.display(26)),
                const SizedBox(height: 8),
                if (children.isEmpty)
                  const EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No entries yet',
                    body: 'Your month will fill up as you add transactions.',
                  )
                else
                  ...children,
              ],
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PocketLogo(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'PocketFin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(26),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatMonth(month),
          style: AppText.data(
            13,
            color: AppColors.muted,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance',
            style: AppText.body(
              18,
              weight: FontWeight.w600,
              color: AppColors.onAccent,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(summary.balanceCents),
              style: AppText.data(
                46,
                weight: FontWeight.w700,
                color: AppColors.onAccent,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BalancePill(
                cents: summary.incomeCents,
                isIncome: true,
              ),
              const SizedBox(width: 10),
              _BalancePill(
                cents: summary.expenseCents,
                isIncome: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.cents, required this.isIncome});

  final int cents;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.lime : AppColors.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isIncome ? '▲' : '▼',
            style: TextStyle(color: color, fontSize: 9, height: 1),
          ),
          const SizedBox(width: 7),
          Text(
            formatMoney(cents, showCents: cents % 100 != 0),
            style: AppText.data(15, color: color),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monthly budget',
                style: AppText.body(20, weight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${summary.budgetPercent}%',
                style: AppText.data(14, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SegmentBar(ratio: summary.budgetRatio),
          const SizedBox(height: 13),
          Text(
            '${formatMoney(summary.expenseCents, showCents: summary.expenseCents % 100 != 0)}'
            ' of ${formatMoney(summary.budgetCents, showCents: summary.budgetCents % 100 != 0)} spent',
            style: AppText.body(15, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.ratio});

  final double ratio;

  static const _segments = 20;

  @override
  Widget build(BuildContext context) {
    final filled = (ratio * _segments).ceil().clamp(0, _segments);
    return Row(
      children: [
        for (var index = 0; index < _segments; index++)
          Expanded(
            child: Container(
              height: 18,
              margin: EdgeInsets.only(right: index == _segments - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: index < filled ? AppColors.coral : AppColors.border,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardLoader extends StatelessWidget {
  const _CardLoader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: Text(
        'Could not load your data.',
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}
