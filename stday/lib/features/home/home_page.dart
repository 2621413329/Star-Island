import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/growth_system.dart';
import '../../data/models/profile_models.dart';
import '../../core/layout/app_layout.dart';
import '../../core/layout/main_shell_insets.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/story_island_models.dart';
import '../../design_system/island_decorations.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/island_weather_provider.dart';
import '../today/add_moment_flow.dart';
import '../today/moment_detail_page.dart';
import 'widgets/all_islands_sheet.dart';
import 'widgets/home_growth_level_card.dart';
import 'widgets/story_entry_card.dart';
import 'widgets/today_story_list.dart';
import 'widgets/world_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({
    super.key,
    required this.enginePaused,
    required this.onRefresh,
    required this.onStoryIslandSelected,
    this.onMainIslandSelected,
    this.onCreateIslandForCategory,
    this.mainIslandTaskSection,
  });

  final bool enginePaused;
  final Future<void> Function() onRefresh;
  final ValueChanged<StoryIslandModel> onStoryIslandSelected;
  final VoidCallback? onMainIslandSelected;
  final Future<void> Function(StoryIslandCategoryModel category)?
      onCreateIslandForCategory;
  final Widget? mainIslandTaskSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 成长、天气和故事列表各自订阅，避免它们的变化把群岛整页重建。
    final shell = MainShellInsets.content(context);
    final palette = ref.watch(moodPaletteProvider);

    return IslandScaffold(
      palette: palette,
      child: RefreshIndicator(
        color: palette.accent,
        onRefresh: onRefresh,
        edgeOffset: shell.top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.pageHorizontal,
                shell.top + 2,
                AppLayout.pageHorizontal,
                0,
              ),
              sliver: const SliverToBoxAdapter(
                child: _HomeGrowthLevelCardHost(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.pageHorizontal,
                16,
                AppLayout.pageHorizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: WorldSection(
                  enginePaused: enginePaused,
                  onIslandSlotTap: (slot) {
                    final island = slot.island;
                    if (island != null) onStoryIslandSelected(island);
                  },
                  onMainIslandTap: onMainIslandSelected,
                  onAllIslandsTap: () => showAllIslandsSheet(
                    context,
                    groups: ref.read(storyIslandGroupsProvider).valueOrNull ??
                        const [],
                    onIslandSelected: onStoryIslandSelected,
                    onCreateIsland: onCreateIslandForCategory,
                  ),
                ),
              ),
            ),
            if (mainIslandTaskSection != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pageHorizontal,
                  12,
                  AppLayout.pageHorizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(child: mainIslandTaskSection!),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.pageHorizontal,
                mainIslandTaskSection != null ? 12 : 12,
                AppLayout.pageHorizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: StoryEntryCard(
                  onStartRecording: () => showAddMomentFlow(context, ref),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.pageHorizontal,
                16,
                AppLayout.pageHorizontal,
                shell.bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: _TodayStoryListHost(
                  onAllRecordsTap: () => context.go('/records'),
                  onStoryTap: (moment) =>
                      openMomentDetailPage(context, moment: moment),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGrowthLevelCardHost extends ConsumerWidget {
  const _HomeGrowthLevelCardHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary =
        ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
    final palette = ref.watch(moodPaletteProvider);
    final weather = ref.watch(islandWeatherProvider).valueOrNull;
    return HomeGrowthLevelCard(
      summary: summary,
      palette: palette,
      weatherKind: islandWeatherKind(weather),
      weatherLabel: weatherDisplayLabelFromSnapshot(weather),
      weather: weather,
    );
  }
}

class _TodayStoryListHost extends ConsumerWidget {
  const _TodayStoryListHost({
    required this.onAllRecordsTap,
    required this.onStoryTap,
  });

  final VoidCallback onAllRecordsTap;
  final void Function(DailyMomentModel moment) onStoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(homeStoryFeedMomentsProvider).valueOrNull ??
        ref.watch(todayMomentsProvider).valueOrNull ??
        const <DailyMomentModel>[];
    final storyGroups =
        ref.watch(storyIslandGroupsProvider).valueOrNull ?? const [];
    return TodayStoryList(
      moments: moments,
      storyGroups: storyGroups,
      palette: ref.watch(moodPaletteProvider),
      onAllRecordsTap: onAllRecordsTap,
      onStoryTap: onStoryTap,
    );
  }
}
