import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/story_island_layout.dart';
import '../../../core/growth/growth_system.dart';
import '../../../core/growth/today_mood_display.dart';
import '../../../data/models/story_island_models.dart';
import '../../../island/providers/growth_summary_provider.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../island/viewport/growth_world_viewport.dart';
import '../../../providers/app_providers.dart';
import '../../../world/preview/story_island_world_builder.dart';

/// 日常投放弹窗中的岛屿缩略预览：主岛显示装饰，副岛显示建筑。
class IslandPlacementPreview extends ConsumerWidget {
  const IslandPlacementPreview({
    super.key,
    required this.island,
    this.width = 72,
    this.height = 52,
  });

  final StoryIslandModel island;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderRadius = BorderRadius.circular(14);
    if (island.isGrowthMainIsland) {
      final summary =
          ref.watch(growthSummaryProvider).valueOrNull ?? GrowthSummary.guest();
      final profile = ref.watch(profileProvider).valueOrNull;
      final moodId = resolveTodayLandingMoodId(profile: profile);
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: width,
          height: height,
          child: GrowthWorldViewport(
            summary: summary,
            moodId: moodId,
            compact: true,
            interactive: false,
            enginePaused: true,
            previewZoom: 2.1,
            islandOnly: true,
            enableDecor: true,
            decorMaxUnlockLevel: 3,
            showBuildings: false,
            showCharacters: false,
            clipCompactPreview: true,
          ),
        ),
      );
    }

      final base = ref.watch(islandWorldPreviewProvider);
    final userLevel =
        ref.watch(growthSummaryProvider).valueOrNull?.level ?? 1;
    final worldState = StoryIslandWorldBuilder.cardPreview(
      base: base,
      island: island,
      userTitleLevel: userLevel,
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: GrowthWorldViewport(
          worldState: worldState,
          compact: true,
          interactive: false,
          enginePaused: true,
          previewZoom: StoryIslandLayout.cardPreviewZoom(island.sizeKind),
          islandOnly: true,
          enableDecor: false,
          showBuildings: true,
          showCharacters: false,
          clipCompactPreview: true,
          force2D: true,
        ),
      ),
    );
  }
}
