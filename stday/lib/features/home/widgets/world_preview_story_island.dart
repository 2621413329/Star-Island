import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/story_island_layout.dart';
import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../island/viewport/growth_world_viewport.dart';
import '../../../world/preview/story_island_world_builder.dart';
import '../../../world/preview/world_preview_camera.dart';
import '../../../world/preview/world_preview_performance.dart';

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
          previewZoom: StoryIslandLayout.mapPreviewZoom(island.sizeKind),
          islandOnly: true,
          enableDecor:
              WorldPreviewPerformance.enableStoryIslandDecor(quality),
          clipCompactPreview: false,
          force2D: true,
        ),
      ),
    );
  }
}
