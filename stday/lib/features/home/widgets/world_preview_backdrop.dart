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

  static const _healingSkyAsset =
      'assets/images/islands/my_islands_background.png';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 治愈风天空底图（图3）。
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD9F0FF),
                  Color(0xFFBFE6FF),
                  Color(0xFFA8D9F5),
                ],
              ),
            ),
          ),
          Image.asset(
            _healingSkyAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // 轻雾叠层，让岛体更贴合治愈风。
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                    const Color(0xFFBFDFFF).withValues(alpha: 0.10),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // 保留淡航线，增强群岛关联；海床/海鸥层弱化以免压过天空图。
          CustomPaint(
            painter: WorldPreviewRouteLayer(
              phase: phase,
              quality: quality,
              activeSlotIds: activeSlotIds,
            ),
            size: size,
          ),
          if (WorldPreviewPerformance.useLifeLayer(quality))
            Opacity(
              opacity: 0.45,
              child: WorldPreviewLifeLayer(phase: phase, quality: quality),
            ),
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
