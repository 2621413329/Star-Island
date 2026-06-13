import 'package:flutter/material.dart';

import '../../../core/models/user_companion.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_period.dart';
import '../../../data/models/mood_report_models.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/island_decorations.dart';
import '../../today/moment_detail_page.dart';
import '../../today/today_story_card.dart';
import 'mood_summary_section.dart';

/// 心情概览 Tab：按当前周期 + 大标签筛选展示故事列表与 AI 心情总结。
class MoodOverviewTab extends StatelessWidget {
  const MoodOverviewTab({
    super.key,
    required this.palette,
    required this.periodLabel,
    required this.filterLabel,
    required this.moments,
    required this.reports,
    required this.period,
    required this.companion,
  });

  final MoodPalette palette;
  final String periodLabel;
  final String filterLabel;
  final List<DailyMomentModel> moments;
  final List<DailyMoodReportModel> reports;
  final MoodStatusPeriod period;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyMomentModel>.from(moments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoodSummarySection(
          palette: palette,
          period: period,
          reports: reports,
        ),
        const SizedBox(height: 18),
        if (sorted.isEmpty)
          _OverviewEmpty(
            palette: palette,
            periodLabel: periodLabel,
            filterLabel: filterLabel,
          )
        else ...[
          Text(
            '$periodLabel · $filterLabel',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${sorted.length} 条心情故事',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8C7B6B),
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TodayStoryCard(
                moment: m,
                companion: companion,
                palette: palette,
                readOnly: true,
                onViewDetail: () => openMomentDetailPage(context, moment: m),
                onPlay: () {},
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OverviewEmpty extends StatelessWidget {
  const _OverviewEmpty({
    required this.palette,
    required this.periodLabel,
    required this.filterLabel,
  });

  final MoodPalette palette;
  final String periodLabel;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(20),
      child: Text(
        '$periodLabel 在「$filterLabel」下还没有心情故事\n试试切换「全部」或其他大标签',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: palette.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
