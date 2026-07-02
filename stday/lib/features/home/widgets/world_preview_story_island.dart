import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../island/viewport/growth_world_viewport.dart';
import '../../../world/preview/story_island_world_builder.dart';
import '../../../world/preview/world_preview_camera.dart';
import '../../../world/preview/world_preview_performance.dart';

double storyIslandPreviewZoom(String sizeKind) {
  final base = switch (sizeKind) {
    'small' => 1.08,
    'medium' => 1.22,
    'large' => 1.36,
    _ => 1.16,
  };
  return base;
}

/// 故事岛首页预览（Flame，仅 high 档部分副岛使用）。
class WorldPreviewStoryIsland extends ConsumerWidget {
  const WorldPreviewStoryIsland({
    super.key,
    required this.island,
    required this.width,
    required this.height,
    required this.enginePaused,
    required this.quality,
  });

  final StoryIslandModel island;
  final double width;
  final double height;
  final bool enginePaused;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldProvider);
    final worldState = StoryIslandWorldBuilder.homeMapPreview(
      base: base,
      island: island,
    );

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: GrowthWorldViewport(
            key: ValueKey(
              'story_map_${island.id}_${island.currentLevel}',
            ),
            worldState: worldState,
            compact: true,
            interactive: false,
            enginePaused: enginePaused,
            previewZoom: storyIslandPreviewZoom(island.sizeKind),
            islandOnly: true,
            enableDecor:
                WorldPreviewPerformance.enableStoryIslandDecor(quality),
            force2D: true,
          ),
        ),
      ),
    );
  }
}
