import 'package:flutter/material.dart';

import '../../../world/preview/world_island_layout.dart';
import '../../../world/preview/world_preview_environment.dart';
import '../../../world/preview/world_preview_performance.dart';

/// 仅包含海域/航线/生命层；与 Flame 岛屿分离，避免每帧 rebuild 视口。
class WorldPreviewBackdrop extends StatelessWidget {
  const WorldPreviewBackdrop({
    super.key,
    required this.phase,
    required this.size,
    required this.quality,
    required this.activeSlotIds,
  });

  final double phase;
  final Size size;
  final WorldPreviewQuality quality;
  final Set<String> activeSlotIds;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WorldPreviewSeabedLayer(phase: phase, quality: quality),
          WorldPreviewOceanLayer(phase: phase, quality: quality),
          WorldPreviewHorizonSkyLayer(phase: phase),
          CustomPaint(
            painter: WorldPreviewRouteLayer(
              phase: phase,
              quality: quality,
              activeSlotIds: activeSlotIds,
            ),
            size: size,
          ),
          if (WorldPreviewPerformance.useLifeLayer(quality))
            WorldPreviewLifeLayer(phase: phase, quality: quality),
          WorldPreviewCloudLayer(phase: phase),
        ],
      ),
    );
  }
}

/// 根据 slot 顺序判断是否用 Flame 渲染副岛。
bool worldPreviewUseFlameForStorySlot({
  required WorldPreviewQuality quality,
  required String slotId,
  required int slotIndexAmongActive,
}) {
  final max = WorldPreviewPerformance.maxFlameStoryIslands(quality);
  return slotIndexAmongActive < max;
}

int storySlotFlameIndex(String slotId) {
  return WorldIslandLayout.storyRankSlotIds.indexOf(slotId);
}
