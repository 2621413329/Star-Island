import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/moment_tags.dart';
import '../../../core/utils/tag_stats.dart';
import '../../../data/models/growth_tag_models.dart';
import '../../../data/models/profile_models.dart';
import '../../../design_system/island_decorations.dart';

/// 标签统计 Tab：按标签库统计一级 / 二级标签触发次数。
class TagStatsTab extends StatelessWidget {
  const TagStatsTab({
    super.key,
    required this.palette,
    required this.periodLabel,
    required this.filterLabel,
    required this.moments,
    required this.categoryFilter,
    required this.catalog,
  });

  final MoodPalette palette;
  final String periodLabel;
  final String filterLabel;
  final List<DailyMomentModel> moments;
  final String? categoryFilter;
  final List<GrowthTagCategoryModel> catalog;

  @override
  Widget build(BuildContext context) {
    if (catalog.isEmpty) {
      return _TagStatsEmpty(
        palette: palette,
        message: '标签库加载中或暂不可用，请稍后重试',
      );
    }

    if (moments.isEmpty) {
      return _TagStatsEmpty(
        palette: palette,
        message: categoryFilter != null
            ? '「$filterLabel」下暂无日常，切换周期或标签后查看统计'
            : '$periodLabel暂无日常记录',
      );
    }

    final selectedCategory = findCategoryByLabel(catalog, categoryFilter);
    final items = categoryFilter == null
        ? primaryTagStatsForMoments(moments, catalog)
        : selectedCategory == null
            ? const <TagStatItem>[]
            : secondaryTagStatsForMoments(
                moments,
                selectedCategory,
                catalog,
              );

    final totalTriggers = tagStatsTotalTriggers(items);
    final activeKinds = tagStatsActiveKindCount(items);
    final maxCount = items.fold<int>(
      0,
      (max, item) => item.count > max ? item.count : max,
    );

    if (totalTriggers == 0) {
      return _TagStatsEmpty(
        palette: palette,
        message: categoryFilter != null
            ? '「$filterLabel」下暂无已识别的标签记录'
            : '当前周期内暂无已识别的标签记录',
      );
    }

    final title = categoryFilter == null
        ? '$periodLabel一级标签 · $filterLabel'
        : '$periodLabel二级标签 · $filterLabel';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '共记录 $totalTriggers 次 · $activeKinds 种标签',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8C7B6B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '仅统计标签库内维护的标签，AI 随机词不会计入',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: palette.primary.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 16),
        IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _TagStatRow(
                  palette: palette,
                  item: items[i],
                  maxCount: maxCount,
                  showRank: categoryFilter == null && items[i].count > 0 && i < 3,
                  rank: i + 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TagStatRow extends StatelessWidget {
  const _TagStatRow({
    required this.palette,
    required this.item,
    required this.maxCount,
    required this.showRank,
    required this.rank,
  });

  final MoodPalette palette;
  final TagStatItem item;
  final int maxCount;
  final bool showRank;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final color = category == null
        ? palette.accent
        : parseHexColor(category.color, fallback: palette.accent);
    final barValue = maxCount == 0 ? 0.0 : item.count / maxCount;

    return Opacity(
      opacity: item.count == 0 ? 0.45 : 1,
      child: Row(
        children: [
          if (showRank && rank <= 3)
            Container(
              width: 22,
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            )
          else
            const SizedBox(width: 22),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category == null
                  ? Icons.label_outline_rounded
                  : growthTagIcon(category.icon),
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count} 次',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: barValue,
                    minHeight: 8,
                    backgroundColor: palette.primaryContainer,
                    color: color.withValues(alpha: 0.72),
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

class _TagStatsEmpty extends StatelessWidget {
  const _TagStatsEmpty({
    required this.palette,
    required this.message,
  });

  final MoodPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.accent.withValues(alpha: 0.12)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: palette.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
