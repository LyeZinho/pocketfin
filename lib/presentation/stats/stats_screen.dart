import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../../logic/analytics.dart';
import '../../logic/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final data = ref.watch(statsDataProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Row(
              children: [
                Text('Stats', style: AppText.display(36)),
                const Spacer(),
                Text(
                  formatMonth(month),
                  style: AppText.data(
                    13,
                    color: AppColors.muted,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedTabs<StatsPeriod>(
              values: StatsPeriod.values,
              selected: period,
              label: (value) => switch (value) {
                StatsPeriod.week => 'Week',
                StatsPeriod.month => 'Month',
                StatsPeriod.year => 'Year',
              },
              onChanged: ref.read(statsPeriodProvider.notifier).select,
            ),
            const SizedBox(height: 20),
            data.when(
              data: (value) => Column(
                children: [
                  _DonutCard(data: value),
                  const SizedBox(height: 16),
                  _DailySpendCard(data: value, period: period),
                  const SizedBox(height: 18),
                  TipCard(text: value.tip),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.lime),
                ),
              ),
              error: (error, stackTrace) => const SurfaceCard(
                child: Text(
                  'Could not load your stats.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({required this.data});

  final StatsData data;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: data.slices.isEmpty
          ? const EmptyState(
              icon: Icons.donut_large_outlined,
              title: 'No spending yet',
              body: 'Add a few expenses to see where your money goes.',
            )
          : Row(
              children: [
                SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 46,
                          startDegreeOffset: -90,
                          sections: [
                            for (final slice in data.slices)
                              PieChartSectionData(
                                value: slice.cents.toDouble(),
                                color: _sliceColor(slice.category),
                                radius: 18,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMoney(
                                data.totalCents,
                                showCents: data.totalCents % 100 != 0,
                              ),
                              style: AppText.data(19, weight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'spent',
                            style: AppText.body(
                              12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      for (final slice in data.slices)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: _sliceColor(slice.category),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slice.category.label,
                                  style: AppText.body(16),
                                ),
                              ),
                              Text(
                                '${slice.percent}%',
                                style: AppText.data(
                                  15,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DailySpendCard extends StatelessWidget {
  const _DailySpendCard({required this.data, required this.period});

  final StatsData data;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    if (data.points.isEmpty) {
      return const SurfaceCard(
        child: EmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'Nothing to chart yet',
          body: 'Your daily rhythm will appear after a few entries.',
        ),
      );
    }

    final maxCents = data.points.fold<int>(
      0,
      (max, point) => point.cents > max ? point.cents : max,
    );
    final maxIndex = data.points.indexWhere((point) => point.cents == maxCents);
    final barWidth = switch (period) {
      StatsPeriod.week => 22.0,
      StatsPeriod.month => 6.0,
      StatsPeriod.year => 14.0,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily spend',
                style: AppText.body(20, weight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'avg ${formatMoney(data.averageCents, showCents: false)}',
                style: AppText.data(13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 172,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCents <= 0 ? 1 : maxCents / 100 * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= data.points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = data.points[index].label;
                        if (label.isEmpty) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            label,
                            style: AppText.data(
                              12,
                              color: AppColors.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < data.points.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.points[index].cents / 100,
                          width: barWidth,
                          color: index == maxIndex && maxCents > 0
                              ? AppColors.lime
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(barWidth / 2),
                        ),
                      ],
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }
}

Color _sliceColor(TxCategory category) {
  return switch (category) {
    TxCategory.food => AppColors.lime,
    TxCategory.home => AppColors.purple,
    TxCategory.fun => AppColors.coral,
    TxCategory.transit => const Color(0xFF5B8DEF),
    TxCategory.health => const Color(0xFFF2C14E),
    TxCategory.bills => AppColors.slate,
    TxCategory.salary => AppColors.lime,
    TxCategory.other => AppColors.slate,
  };
}
