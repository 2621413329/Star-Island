import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/emotion_catalog.dart';
import '../../core/utils/moment_tags.dart';
import '../../data/models/growth_tag_models.dart';
import '../../data/models/profile_models.dart';
import '../../providers/growth_tag_provider.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/mood_period.dart';
import '../../core/utils/mood_stats.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_icon.dart';
import '../../providers/app_providers.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/member_provider.dart';
import '../../core/membership/vip_guard.dart';
import '../shared/widgets/mood_companion_loading.dart';
import 'widgets/mood_summary_section.dart';
import 'widgets/mood_overview_tab.dart';
import 'widgets/mood_period_filter_bar.dart';
import 'widgets/mood_stats_tab.dart';
import 'widgets/mood_status_section_tabs.dart';
import 'widgets/tag_stats_tab.dart';

class MoodStatusPage extends ConsumerStatefulWidget {
  const MoodStatusPage({super.key});

  @override
  ConsumerState<MoodStatusPage> createState() => _MoodStatusPageState();
}

class _MoodStatusPageState extends ConsumerState<MoodStatusPage> {
  int _sectionTabIndex = 0;

  void _selectPeriod(MoodStatusPeriod period) {
    ref.read(moodStatusPageProvider.notifier).state = 1;
    ref.read(moodStatusPeriodProvider.notifier).state = period;
    ref.read(moodStatusCategoryFilterProvider.notifier).state = null;
    ref.read(moodStatusEmotionFilterProvider.notifier).state = null;
  }

  void _selectCategory(String? label) {
    ref.read(moodStatusPageProvider.notifier).state = 1;
    ref.read(moodStatusCategoryFilterProvider.notifier).state = label;
  }

  void _selectEmotion(String? id) {
    ref.read(moodStatusPageProvider.notifier).state = 1;
    ref.read(moodStatusEmotionFilterProvider.notifier).state = id;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final statusAsync = ref.watch(moodStatusViewProvider);
    final selectedPeriod = ref.watch(moodStatusPeriodProvider);
    final categoryFilter = ref.watch(moodStatusCategoryFilterProvider);
    final emotionFilter = ref.watch(moodStatusEmotionFilterProvider);

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
        final isVip = ref.watch(isVipProvider);
        ref.watch(memberProvider);
        final summaryAsync = ref.watch(
          moodPeriodSummaryProvider(
            MoodSummaryKey(
              period: selectedPeriod,
              categoryFilter: categoryFilter,
            ),
          ),
        );
        final summary = summaryAsync.valueOrNull;
        final useServerStats =
            view.isPaginated && summary != null && summary.totalMoments > 0;
        final counts = useServerStats
            ? summary.moodCounts
            : moodCountsForMoments(
                moments,
                categoryLabel: categoryFilter,
                emotionFilterId: emotionFilter,
              );
        final total = useServerStats
            ? summary.totalMoments
            : moodTotalForFilter(
                moments,
                categoryLabel: categoryFilter,
                emotionFilterId: emotionFilter,
              );
        final dominantId = useServerStats && summary.dominantMood != null
            ? normalizeEmotionId(summary.dominantMood)
            : dominantMoodId(counts);
        final dominant = dominantId != null ? emotionById(dominantId) : null;
        final displayEmotion =
            emotionFilter != null ? emotionById(emotionFilter) : dominant;
        final filteredMoments = view.isPaginated
            ? moments
            : moments.where((m) {
                if (categoryFilter != null &&
                    !momentMatchesCategory(m, categoryFilter)) {
                  return false;
                }
                if (emotionFilter != null &&
                    effectiveEmotionIdForMoment(m) != emotionFilter) {
                  return false;
                }
                return true;
              }).toList();
        final tagCatalog =
            ref.watch(growthTagCatalogProvider).valueOrNull ?? const [];
        final tagStatsKey = MoodSummaryKey(
          period: selectedPeriod,
          categoryFilter: categoryFilter,
        );
        final tagStatsMomentsAsync = isVip
            ? ref.watch(moodStatusAllMomentsProvider(tagStatsKey))
            : const AsyncValue<List<DailyMomentModel>>.data([]);
        final tagStatsMoments = isVip
            ? (tagStatsMomentsAsync.valueOrNull ??
                (view.isPaginated ? const <DailyMomentModel>[] : moments))
            : const <DailyMomentModel>[];
        final filterLabel = _buildFilterLabel(
          categoryFilter: categoryFilter,
          emotionFilter: emotionFilter,
        );
        final hasActiveFilter = categoryFilter != null || emotionFilter != null;
        final hasAnyMoments = view.isPaginated
            ? (summary?.totalMoments ?? view.total) > 0 || view.total > 0
            : moments.isNotEmpty;
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
                      Text(
                        '成长轨迹',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$periodLabel · 按成长标签查看心情分布',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.primary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MoodPeriodFilterBar(
                        palette: palette,
                        selected: selectedPeriod,
                        onSelected: _selectPeriod,
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
                          categories: tagCatalog,
                          selectedLabel: categoryFilter,
                          onSelected: _selectCategory,
                        ),
                        const SizedBox(height: 14),
                        MoodSummarySection(
                          palette: palette,
                          period: selectedPeriod,
                          summaryAsync: summaryAsync,
                          locked: !isVip,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '感受筛选',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _EmotionFilterRow(
                          palette: palette,
                          emotions: emotionStatsCatalog(),
                          selectedId: emotionFilter,
                          gender: gender,
                          onSelected: _selectEmotion,
                        ),
                        const SizedBox(height: 14),
                        _DaySummaryCard(
                          palette: palette,
                          dominant: displayEmotion,
                          total: total,
                          filterLabel: filterLabel,
                          hasCategoryFilter:
                              categoryFilter != null || emotionFilter != null,
                          gender: gender,
                          summaryTitle: view.summaryTitle,
                          showMoodFace: displayEmotion != null,
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
                          child: switch (sectionTabs[safeTabIndex].id) {
                            'overview' => MoodOverviewTab(
                                key: ValueKey(
                                  'overview-$filterLabel-${view.period}-${view.page}',
                                ),
                                palette: palette,
                                periodLabel: periodLabel,
                                filterLabel: filterLabel,
                                moments: filteredMoments,
                                period: view.period,
                                companion: companion,
                                categoryFilter: categoryFilter,
                                total: view.total,
                                page: view.page,
                                totalPages: view.totalPages,
                                isPaginated: view.isPaginated,
                                onPageSelected: (p) => ref
                                    .read(moodStatusViewProvider.notifier)
                                    .goToPage(p),
                              ),
                            'stats' => VipFeatureMask(
                                locked: !isVip,
                                message: '开通 VIP 查看心情统计',
                                child: isVip
                                    ? MoodStatsTab(
                                        key: ValueKey(
                                          'stats-$filterLabel-${view.period}',
                                        ),
                                        palette: palette,
                                        periodLabel: periodLabel,
                                        filterLabel: filterLabel,
                                        moments: moments,
                                        categoryFilter: categoryFilter,
                                        emotionFilterId: emotionFilter,
                                        gender: gender,
                                        showMoodFaces: true,
                                        moodCountsOverride: useServerStats
                                            ? summary.moodCounts
                                            : null,
                                        totalOverride: useServerStats
                                            ? summary.totalMoments
                                            : null,
                                      )
                                    : _LockedMoodStatsPreview(
                                        palette: palette,
                                        periodLabel: periodLabel,
                                      ),
                              ),
                            _ => VipFeatureMask(
                                locked: !isVip,
                                message: '开通 VIP 查看标签统计',
                                child: isVip
                                    ? TagStatsTab(
                                        key: ValueKey(
                                          'tag-stats-$filterLabel-${view.period}',
                                        ),
                                        palette: palette,
                                        periodLabel: periodLabel,
                                        filterLabel: filterLabel,
                                        moments: tagStatsMoments,
                                        categoryFilter: categoryFilter,
                                        catalog: tagCatalog,
                                        loading: view.isPaginated &&
                                            tagStatsMomentsAsync.isLoading,
                                      )
                                    : _LockedTagStatsPreview(
                                        palette: palette,
                                        periodLabel: periodLabel,
                                      ),
                              ),
                          },
                        ),
                        const SizedBox(height: 8),
                      ] else if (!hasAnyMoments) ...[
                        const SizedBox(height: 36),
                        _EmptyMoodStatusCard(
                          palette: palette,
                          periodLabel: periodLabel,
                          hasActiveFilter: hasActiveFilter,
                          onClearFilter: hasActiveFilter
                              ? () {
                                  ref
                                      .read(moodStatusCategoryFilterProvider
                                          .notifier)
                                      .state = null;
                                  ref
                                      .read(moodStatusEmotionFilterProvider
                                          .notifier)
                                      .state = null;
                                  ref
                                      .read(moodStatusPageProvider.notifier)
                                      .state = 1;
                                }
                              : null,
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

String _buildFilterLabel({
  String? categoryFilter,
  String? emotionFilter,
}) {
  final parts = <String>[];
  if (categoryFilter != null) parts.add(categoryFilter);
  if (emotionFilter != null) parts.add(emotionLabel(emotionFilter));
  if (parts.isEmpty) return '全部';
  return parts.join(' · ');
}

class _EmptyMoodStatusCard extends StatelessWidget {
  const _EmptyMoodStatusCard({
    required this.palette,
    required this.periodLabel,
    required this.hasActiveFilter,
    this.onClearFilter,
  });

  final MoodPalette palette;
  final String periodLabel;
  final bool hasActiveFilter;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasActiveFilter
                ? '$periodLabel当前筛选下没有日常记录'
                : '$periodLabel还没有日常记录，记下日常后这里会显示心情统计',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: palette.primary.withValues(alpha: 0.65),
            ),
          ),
          if (hasActiveFilter && onClearFilter != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('清除筛选'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmotionFilterRow extends StatelessWidget {
  const _EmotionFilterRow({
    required this.palette,
    required this.emotions,
    required this.selectedId,
    required this.onSelected,
    this.gender,
  });

  final MoodPalette palette;
  final List<EmotionDefinition> emotions;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    const chipSize = 42.0;
    return SizedBox(
      height: chipSize + 14,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: Clip.none,
        children: [
          _CategoryFilterChip(
            icon: Icons.sentiment_satisfied_alt_outlined,
            semanticLabel: '全部心情',
            label: '全部',
            selected: selectedId == null,
            color: palette.accent,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final emotion in emotions) ...[
            _EmotionFilterChip(
              emotion: emotion,
              selected: selectedId == emotion.id,
              size: chipSize,
              gender: gender,
              onTap: () => onSelected(emotion.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.palette,
    required this.categories,
    required this.selectedLabel,
    required this.onSelected,
  });

  final MoodPalette palette;
  final List<GrowthTagCategoryModel> categories;
  final String? selectedLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 3),
        clipBehavior: Clip.none,
        children: [
          _CategoryFilterChip(
            icon: Icons.apps_rounded,
            semanticLabel: '全部',
            label: '全部',
            selected: selectedLabel == null,
            color: palette.accent,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 7),
          for (final category in categories)
            if (category.isActive) ...[
              _CategoryFilterChip(
                icon: _categoryIcon(category.id, category.icon),
                semanticLabel: category.label,
                label: category.label,
                selected: selectedLabel == category.label,
                color: parseHexColor(category.color, fallback: palette.accent),
                onTap: () => onSelected(category.label),
              ),
              const SizedBox(width: 7),
            ],
        ],
      ),
    );
  }

  IconData _categoryIcon(String id, String fallbackIcon) {
    return switch (id) {
      'work' => Icons.work_rounded,
      'study' => Icons.school_rounded,
      'health' => Icons.eco_rounded,
      'social' => Icons.favorite_border_rounded,
      'life' => Icons.home_rounded,
      'finance' || 'wealth' => Icons.shield_outlined,
      _ => growthTagIcon(fallbackIcon),
    };
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.palette,
    required this.dominant,
    required this.total,
    required this.filterLabel,
    required this.hasCategoryFilter,
    required this.summaryTitle,
    required this.showMoodFace,
    this.gender,
  });

  final MoodPalette palette;
  final EmotionDefinition? dominant;
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
                        hasCategoryFilter ? '当前筛选' : '主导感受',
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
                Text(
                  '共 $total 条',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            )
          else if (hasCategoryFilter)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前筛选',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.primary.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        filterLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _LockedMoodStatsPreview extends StatelessWidget {
  const _LockedMoodStatsPreview({
    required this.palette,
    required this.periodLabel,
  });

  final MoodPalette palette;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final demo = emotionStatsCatalog().take(5).toList();
    const demoValues = [0.72, 0.54, 0.38, 0.26, 0.18];
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel感受 · 全部标签',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '共 12 条感受记录',
            style: TextStyle(
              fontSize: 13,
              color: palette.primary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < demo.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  MoodFaceIcon(
                    type: demo[i].faceType,
                    color: demo[i].color,
                    size: 28,
                    moodId: demo[i].id,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: Text(
                      demo[i].label,
                      style: TextStyle(
                        color: demo[i].color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: demoValues[i],
                        minHeight: 10,
                        backgroundColor: palette.primaryContainer,
                        color: demo[i].color.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(demoValues[i] * 100).round()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedTagStatsPreview extends StatelessWidget {
  const _LockedTagStatsPreview({
    required this.palette,
    required this.periodLabel,
  });

  final MoodPalette palette;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    const labels = ['工作学习', '身体关怀', '关系连接', '自我觉察'];
    const values = [0.78, 0.62, 0.44, 0.30];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$periodLabel一级标签 · 全部标签',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '共记录 18 次 · 6 种标签',
          style: TextStyle(
            fontSize: 13,
            color: palette.primary.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),
        IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: palette.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 72,
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: values[i],
                            minHeight: 9,
                            backgroundColor: palette.primaryContainer
                                .withValues(alpha: 0.62),
                            color: palette.accent.withValues(alpha: 0.58),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmotionFilterChip extends StatelessWidget {
  const _EmotionFilterChip({
    required this.emotion,
    required this.selected,
    required this.size,
    required this.onTap,
    this.gender,
  });

  final EmotionDefinition emotion;
  final bool selected;
  final double size;
  final VoidCallback onTap;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: emotion.label,
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
                  ? emotion.color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? emotion.color
                    : emotion.color.withValues(alpha: 0.35),
                width: selected ? 2 : 1,
              ),
            ),
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(size * 0.06),
                child: MoodFaceIcon(
                  type: emotion.faceType,
                  color: emotion.color,
                  size: size * 0.68,
                  moodId: emotion.id,
                  gender: gender,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.icon,
    required this.semanticLabel,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF6E5A4A);
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: Material(
        color: selected ? color : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.35)
                    : color.withValues(alpha: 0.22),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
