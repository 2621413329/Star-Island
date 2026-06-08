import 'package:flutter/material.dart';

import '../../../core/models/user_companion.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/island_decorations.dart';
import '../../today/moment_detail_page.dart';
import '../../today/today_story_card.dart';

/// 心情概览 Tab：按当前日期 + 大标签筛选展示故事列表。
class MoodOverviewTab extends StatelessWidget {
  const MoodOverviewTab({
    super.key,
    required this.palette,
    required this.dayLabel,
    required this.filterLabel,
    required this.moments,
    required this.companion,
  });

  final MoodPalette palette;
  final String dayLabel;
  final String filterLabel;
  final List<DailyMomentModel> moments;
  final UserCompanion companion;

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyMomentModel>.from(moments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sorted.isEmpty) {
      return _OverviewEmpty(
        palette: palette,
        dayLabel: dayLabel,
        filterLabel: filterLabel,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$dayLabel · $filterLabel',
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
    );
  }
}

class _OverviewEmpty extends StatelessWidget {
  const _OverviewEmpty({
    required this.palette,
    required this.dayLabel,
    required this.filterLabel,
  });

  final MoodPalette palette;
  final String dayLabel;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(20),
      child: Text(
        '$dayLabel 在「$filterLabel」下还没有心情故事\n试试切换「全部」或其他大标签',
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
