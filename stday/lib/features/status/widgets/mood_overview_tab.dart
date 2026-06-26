import 'package:flutter/material.dart';

import '../../../core/models/user_companion.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_period.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/island_pagination_bar.dart';
import '../../today/moment_detail_page.dart';
import '../../today/today_story_card.dart';

/// 心情概览 Tab：按当前周期 + 大标签筛选展示日常列表。
class MoodOverviewTab extends StatelessWidget {
  const MoodOverviewTab({
    super.key,
    required this.palette,
    required this.periodLabel,
    required this.filterLabel,
    required this.moments,
    required this.period,
    required this.companion,
    required this.categoryFilter,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.isPaginated,
    required this.onPageSelected,
  });

  final MoodPalette palette;
  final String periodLabel;
  final String filterLabel;
  final List<DailyMomentModel> moments;
  final MoodStatusPeriod period;
  final UserCompanion companion;
  final String? categoryFilter;
  final int total;
  final int page;
  final int totalPages;
  final bool isPaginated;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyMomentModel>.from(moments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final itemCount = isPaginated ? total : sorted.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$periodLabel · $filterLabel',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isPaginated ? '共 $total 条心情日常' : '共 $itemCount 条心情日常',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8C7B6B),
          ),
        ),
        if (sorted.isNotEmpty) ...[
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
          if (isPaginated)
            IslandPaginationBar(
              palette: palette,
              page: page,
              totalPages: totalPages,
              totalItems: total,
              onPageSelected: onPageSelected,
            ),
        ],
      ],
    );
  }
}
