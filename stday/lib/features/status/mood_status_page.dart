import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/mood_period.dart';
import '../../core/utils/mood_stats.dart';
import '../../data/models/mood_check_in_models.dart';
import '../../design_system/companion_loading.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_report_check_in_provider.dart';
import '../../providers/mood_status_provider.dart';
import 'widgets/mood_check_in_week_card.dart';
import 'widgets/mood_overview_tab.dart';
import 'widgets/mood_period_filter_bar.dart';
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
    final statusAsync = ref.watch(moodStatusViewProvider);
    final checkInAsync = ref.watch(moodReportCheckInProvider);
    final selectedPeriod = ref.watch(moodStatusPeriodProvider);

    return statusAsync.when(
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
        final periodLabel = view.periodLabel;
        final companion = ref.watch(userCompanionProvider);
        final gender = companion.gender;
        final profile = ref.watch(profileProvider).valueOrNull;
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
                        '$periodLabel · 按大标签查看心情分布',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.primary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MoodPeriodFilterBar(
                        palette: palette,
                        selected: selectedPeriod,
                        todayMoodId: profile?.todayMood,
                        gender: gender,
                        onSelected: (period) {
                          ref.read(moodStatusPeriodProvider.notifier).state =
                              period;
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
                          gender: gender,
                          summaryTitle: view.summaryTitle,
                          showMoodFace:
                              view.period == MoodStatusPeriod.today,
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
                                    'overview-$filterLabel-${view.period}',
                                  ),
                                  palette: palette,
                                  periodLabel: periodLabel,
                                  filterLabel: filterLabel,
                                  moments: filteredMoments,
                                  reports: view.reports,
                                  period: view.period,
                                  companion: companion,
                                )
                              : MoodStatsTab(
                                  key: ValueKey(
                                    'stats-$filterLabel-${view.period}',
                                  ),
                                  palette: palette,
                                  periodLabel: periodLabel,
                                  filterLabel: filterLabel,
                                  moments: moments,
                                  categoryFilter: _categoryFilter,
                                  gender: gender,
                                  showMoodFaces:
                                      view.period == MoodStatusPeriod.today,
                                ),
                        ),
                        const SizedBox(height: 8),
                      ] else if (!hasAnyMoments) ...[
                        const SizedBox(height: 36),
                        IslandGlassCard(
                          palette: palette,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '$periodLabel还没有故事记录，记下故事后这里会显示心情统计',
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
    const chipSize = 42.0;
    return SizedBox(
      height: chipSize + 4,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _CategoryFilterChip(
            icon: Icons.apps_rounded,
            semanticLabel: '全部',
            selected: selectedId == null,
            color: palette.accent,
            size: chipSize,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final tag in eventTags) ...[
            _CategoryFilterChip(
              asset: tag.asset,
              emoji: tag.asset == null ? tag.emoji : null,
              semanticLabel: tag.label,
              selected: selectedId == tag.id,
              color: tag.color,
              size: chipSize,
              onTap: () => onSelected(tag.id),
            ),
            const SizedBox(width: 8),
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
    required this.summaryTitle,
    required this.showMoodFace,
    this.gender,
  });

  final MoodPalette palette;
  final MoodOption? dominant;
  final List<EventTagCount> topTags;
  final int total;
  final String filterLabel;
  final bool hasCategoryFilter;
  final String summaryTitle;
  final bool showMoodFace;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summaryTitle,
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
                if (showMoodFace)
                  MoodFaceIcon(
                    type: dominant!.faceType,
                    color: dominant!.color,
                    size: 36,
                    moodId: dominant!.id,
                    gender: gender,
                  )
                else
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dominant!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                SizedBox(width: showMoodFace ? 10 : 8),
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
          if (tag.asset != null)
            SizedBox(
              width: compact ? 18 : 22,
              height: compact ? 18 : 22,
              child: Image.asset(
                tag.asset!,
                fit: BoxFit.contain,
              ),
            )
          else
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
    this.asset,
    required this.semanticLabel,
    required this.selected,
    required this.color,
    required this.onTap,
    this.size = 48,
  }) : assert(emoji != null || icon != null || asset != null);

  final String? emoji;
  final IconData? icon;
  final String? asset;
  final String semanticLabel;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.68;
    final emojiSize = size * 0.56;
    final assetSize = size * 0.88;
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: selected ? 1.08 : 1,
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
            ),
            child: asset != null
                ? ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.06),
                      child: Image.asset(
                        asset!,
                        width: assetSize,
                        height: assetSize,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: iconSize,
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : icon != null
                    ? Icon(
                        icon,
                        size: iconSize,
                        color: selected ? color : const Color(0xFF6E5A4A),
                      )
                    : Text(emoji!, style: TextStyle(fontSize: emojiSize)),
          ),
        ),
      ),
    );
  }
}
