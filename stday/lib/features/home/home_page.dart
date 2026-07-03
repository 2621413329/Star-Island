import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/layout/main_shell_insets.dart';
import '../../core/weather/weather_display.dart';
import '../../data/models/story_island_models.dart';
import '../../design_system/home_theme.dart';
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
    final momentsAsync = ref.watch(recentStoryMomentsProvider);
    final moments = momentsAsync.valueOrNull ??
        ref.watch(todayMomentsProvider).valueOrNull ??
        const [];
    final storyGroups =
        ref.watch(storyIslandGroupsProvider).valueOrNull ?? const [];
    final shell = MainShellInsets.content(context);
    final palette = ref.watch(moodPaletteProvider);
    final summary =
        ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
    final weather = ref.watch(islandWeatherProvider).valueOrNull;
    final weatherKind = islandWeatherKind(weather);
    final weatherLabel = weatherDisplayLabelFromSnapshot(weather);

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
                shell.top + 8,
                AppLayout.pageHorizontal,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: HomeGrowthLevelCard(
                  summary: summary,
                  palette: palette,
                  weatherKind: weatherKind,
                  weatherLabel: weatherLabel,
                  weather: weather,
                ),
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
                    groups: storyGroups,
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
                child: TodayStoryList(
                  moments: moments,
                  storyGroups: storyGroups,
                  palette: palette,
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
