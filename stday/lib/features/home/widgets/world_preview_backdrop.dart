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
  });

  final double phase;
  final Size size;
  final WorldPreviewQuality quality;

  static const healingSkyAsset =
      'assets/images/islands/my_islands_background.png';

  @override
  Widget build(BuildContext context) {
    // 天空、薄雾和航线画进外层群岛边界，静止时合成成一层。
    return Stack(
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
            healingSkyAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            cacheWidth: (size.width * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(360, 1280),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // 压低底图花叶，让岛体成为画面主体。
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66F4FBFF),
                    Color(0x14FFFFFF),
                    Color(0x73E7F3FF),
                  ],
                  stops: [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.08),
                  radius: 1.05,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0x337EAFD4),
                  ],
                  stops: [0.58, 1.0],
                ),
              ),
            ),
          ),
          if (WorldPreviewPerformance.useLifeLayer(quality))
            Opacity(
              opacity: 0.45,
              child: WorldPreviewLifeLayer(phase: phase, quality: quality),
            ),
        ],
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
