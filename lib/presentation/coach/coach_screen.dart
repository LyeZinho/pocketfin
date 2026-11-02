import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pocket_widgets.dart';
import '../../logic/analytics.dart';
import '../../logic/providers.dart';
import '../export/export_section.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              'Coach & export',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(36),
            ),
            const SizedBox(height: 6),
            Text(
              'Advice from your own history',
              style: AppText.body(17, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            insights.when(
              data: (list) => _Insights(insights: list),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.lime),
                ),
              ),
              error: (error, stackTrace) => const SurfaceCard(
                child: Text(
                  'Could not build your insights.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const ExportSection(),
          ],
        ),
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const SurfaceCard(
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'Your coach is listening',
          body: 'Log a few expenses and tailored insights will show up here.',
        ),
      );
    }

    final first = insights.first;
    final rest = insights.skip(1).take(2).toList();

    return Column(
      children: [
        _LargeInsight(insight: first, index: 1),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (rest.length == 1)
            _SmallInsight(insight: rest.first, index: 2)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SmallInsight(insight: rest[0], index: 2)),
                const SizedBox(width: 12),
                Expanded(child: _SmallInsight(insight: rest[1], index: 3)),
              ],
            ),
        ],
      ],
    );
  }
}

class _LargeInsight extends StatelessWidget {
  const _LargeInsight({required this.insight, required this.index});

  final Insight insight;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(insight.tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSIGHT ${index.toString().padLeft(2, '0')}',
            style: AppText.data(
              12,
              color: AppColors.onAccent.withValues(alpha: 0.65),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: AppText.display(
              27,
              color: AppColors.onAccent,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insight.body,
            style: AppText.body(
              16,
              color: AppColors.onAccent.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInsight extends StatelessWidget {
  const _SmallInsight({required this.insight, required this.index});

  final Insight insight;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(insight.tone);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSIGHT ${index.toString().padLeft(2, '0')}',
            style: AppText.data(11, color: color, letterSpacing: 1.8),
          ),
          const SizedBox(height: 12),
          Text(
            insight.title,
            style: AppText.body(18, weight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            insight.body,
            style: AppText.body(13.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(InsightTone tone) {
  return switch (tone) {
    InsightTone.purple => AppColors.purple,
    InsightTone.lime => AppColors.lime,
    InsightTone.coral => AppColors.coral,
  };
}
