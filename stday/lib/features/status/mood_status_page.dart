import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/mood_stats.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/story_day_provider.dart';
import '../today/widgets/story_day_filter_bar.dart';
import 'widgets/mood_check_in_week_card.dart';
import 'widgets/mood_overview_tab.dart';
import 'widgets/mood_stats_tab.dart';
import 'widgets/mood_status_section_tabs.dart';

class MoodStatusPage extends ConsumerStatefulWidget {
  const MoodStatusPage({super.key});

  @override
  ConsumerState<MoodStatusPage> createState() => _MoodStatusPageState();
}

class _MoodStatusPageState extends ConsumerState<MoodStatusPage> {
  String? _categoryFilter;
  int _sectionTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(moodReportCheckInProvider));
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final storyAsync = ref.watch(storyDayViewProvider);
    final checkInAsync = ref.watch(moodReportCheckInProvider);

    return storyAsync.when(
      loading: () => const MoodCompanionLoadingBody(
        message: '正在感受你的心情…',
      ),
      error: (e, _) => IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Center(child: Text('加载失败：$e')),
        ),
      ),
      data: (view) {
        final moments = view.moments;
        final dayLabel = formatMomentDateLabel(view.selectedDay);
        final profile = ref.watch(profileProvider).valueOrNull;
        final companionStyle = profile?.companionStyle ?? 'chibi';
        final counts =
            moodCountsForMoments(moments, categoryId: _categoryFilter);
        final total = moodTotalForFilter(moments, categoryId: _categoryFilter);
        final dominantId = dominantMoodId(counts);
        final dominant = dominantId != null ? moodById(dominantId) : null;
        final filteredMoments = _categoryFilter == null
            ? moments
            : moments
                .where(
                  (m) =>
                      m.eventTags.isNotEmpty &&
                      m.eventTags.first == _categoryFilter,
                )
                .toList();
        final topTags = topEventTagsForMoments(filteredMoments);
        final filterLabel = _categoryFilter == null
            ? '全部'
            : eventTags
                .firstWhere(
                  (e) => e.id == _categoryFilter,
                  orElse: () => eventTags.last,
                )
                .label;
        final checkIn = checkInAsync.valueOrNull ?? MoodReportCheckIn.empty;
        final hasAnyMoments = moments.isNotEmpty;
        final sectionTabs = MoodStatusSectionTabs.all;
        final safeTabIndex = _sectionTabIndex.clamp(0, sectionTabs.length - 1);

        return IslandScaffold(
          palette: palette,
          child: SafeArea(
            child: CustomScrollView(
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.pageHorizontal,
                      16,
                      AppLayout.pageHorizontal,
                      24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        MoodCheckInWeekCard(
                          palette: palette,
                          checkIn: checkIn,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '心情状态',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$dayLabel · 按大标签查看心情分布',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.primary.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StoryDayFilterBar(
                          palette: palette,
                          selectedDay: view.selectedDay,
                          recordedDays: view.recordedDays,
                          moodByDayIso: view.moodByDayIso,
                          onDaySelected: (day) {
                            ref.read(selectedStoryDayProvider.notifier).state =
                                calendarDate(day);
                          },
                        ),
                        if (hasAnyMoments) ...[
                          const SizedBox(height: 12),
                          Text(
                            '标签筛选',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CategoryFilterRow(
                            palette: palette,
                            selectedId: _categoryFilter,
                            onSelected: (id) =>
                                setState(() => _categoryFilter = id),
                          ),
                          const SizedBox(height: 14),
                          _DaySummaryCard(
                            palette: palette,
                            dominant: dominant,
                            topTags: topTags,
                            total: total,
                            filterLabel: filterLabel,
                            hasCategoryFilter: _categoryFilter != null,
                          ),
                          const SizedBox(height: 16),
                          MoodStatusSectionTabBar(
                            palette: palette,
                            tabs: sectionTabs,
                            selectedIndex: safeTabIndex,
                            onSelected: (i) =>
                                setState(() => _sectionTabIndex = i),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: sectionTabs[safeTabIndex].id ==
                                    MoodStatusSectionTabs.overview.id
                                ? MoodOverviewTab(
                                    key: ValueKey(
                                      'overview-$filterLabel-${view.selectedDay}',
                                    ),
                                    palette: palette,
                                    dayLabel: dayLabel,
                                    filterLabel: filterLabel,
                                    moments: filteredMoments,
                                    companionStyle: companionStyle,
                                    companionGender: profile?.gender,
                                  )
                                : MoodStatsTab(
                                    key: ValueKey(
                                      'stats-$filterLabel-${view.selectedDay}',
                                    ),
                                    palette: palette,
                                    dayLabel: dayLabel,
                                    filterLabel: filterLabel,
                                    moments: moments,
                                    categoryFilter: _categoryFilter,
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ] else if (!hasAnyMoments) ...[
                          IslandGlassCard(
                            palette: palette,
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              '这一天还没有故事记录，记下故事后这里会显示心情统计',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.primary.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.palette,
    required this.selectedId,
    required this.onSelected,
  });

  final MoodPalette palette;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryFilterChip(
            icon: Icons.apps_rounded,
            semanticLabel: '全部',
            selected: selectedId == null,
            color: palette.accent,
            size: 36,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 6),
          for (final tag in eventTags) ...[
            _CategoryFilterChip(
              emoji: tag.emoji,
              semanticLabel: tag.label,
              selected: selectedId == tag.id,
              color: tag.color,
              size: 36,
              onTap: () => onSelected(tag.id),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.palette,
    required this.dominant,
    required this.topTags,
    required this.total,
    required this.filterLabel,
    required this.hasCategoryFilter,
  });

  final MoodPalette palette;
  final MoodOption? dominant;
  final List<EventTagCount> topTags;
  final int total;
  final String filterLabel;
  final bool hasCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当日概览',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 12),
          if (dominant != null)
            Row(
              children: [
                MoodFaceIcon(
                  type: dominant!.faceType,
                  color: dominant!.color,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主导心情',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        dominant!.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: dominant!.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (total > 0)
                  Text(
                    '共 $total 条',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.primary.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: palette.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                hasCategoryFilter
                    ? '「$filterLabel」下还没有相关心情记录'
                    : '当前还没有可统计的心情记录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: palette.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (topTags.isNotEmpty && !hasCategoryFilter) ...[
            const SizedBox(height: 14),
            Text(
              '大标签 Top3',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < topTags.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _TopTagChip(
                      tagId: topTags[i].tagId,
                      count: topTags[i].count,
                      palette: palette,
                      compact: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopTagChip extends StatelessWidget {
  const _TopTagChip({
    required this.tagId,
    required this.count,
    required this.palette,
    this.compact = false,
  });

  final String tagId;
  final int count;
  final MoodPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tag = eventTags.firstWhere(
      (e) => e.id == tagId,
      orElse: () => eventTags.last,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: tag.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.emoji, style: TextStyle(fontSize: compact ? 14 : 18)),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              compact ? '${tag.label}·$count' : '${tag.label} · $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    this.emoji,
    this.icon,
    required this.semanticLabel,
    required this.selected,
    required this.color,
    required this.onTap,
    this.size = 48,
  }) : assert(emoji != null || icon != null);

  final String? emoji;
  final IconData? icon;
  final String semanticLabel;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.58;
    final emojiSize = size * 0.48;
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 6,
                      spreadRadius: 0.3,
                    ),
                  ]
                : null,
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: iconSize,
                  color: selected ? color : const Color(0xFF6E5A4A),
                )
              : Text(emoji!, style: TextStyle(fontSize: emojiSize)),
        ),
      ),
    );
  }
}
