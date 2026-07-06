import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_world_provider.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/story_island_building_icon.dart';
import '../../../world/preview/world_preview_camera.dart';

/// 副岛静态预览：绘制岛体 + 建筑 PNG（无 Flame，低端机兜底）。
class WorldPreviewStoryIslandStatic extends ConsumerWidget {
  const WorldPreviewStoryIslandStatic({
    super.key,
    required this.island,
    required this.width,
    required this.height,
  });

  final StoryIslandModel island;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldPreviewProvider);
    final previewIsland = IslandState(
      shapeKey: base.island.shapeKey,
      style: base.island.style,
      elevation: base.island.elevation,
      prosperityTier: base.island.prosperityTier,
      radius: 0.78,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final asset = StoryIslandBuildingIcon.previewAsset(
      categoryId: island.categoryId,
      island: island,
    );
    final cacheW = (width * dpr).round().clamp(64, 512);

    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: WorldPreviewCamera.islandTransform(),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: _CompactIslandPreviewPainter(
                island: previewIsland,
                environment: base.environment,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: height * 0.04,
              ),
              child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.low,
                  cacheWidth: cacheW,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.landscape_outlined,
                    size: width * 0.35,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _CompactIslandPreviewPainter extends CustomPainter {
  _CompactIslandPreviewPainter({
    required this.island,
    required this.environment,
  });

  final IslandState island;
  final MoodEnvironmentState environment;

  static final _renderer = IslandRenderer(compact: true);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, size, island, environment);
  }

  @override
  bool shouldRepaint(covariant _CompactIslandPreviewPainter oldDelegate) {
    return oldDelegate.island.radius != island.radius ||
        oldDelegate.island.prosperityTier != island.prosperityTier;
  }
}
