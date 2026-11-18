import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_preview_body.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_body_image_cache.dart';
import '../../../world/island/island_visual_config.dart';
import '../../../world/preview/story_island_building_icon.dart';
import '../../../world/preview/world_preview_camera.dart';

/// 副岛静态预览：岛体 + 顶部最高等级建筑 PNG（无 Flame）。
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
    final style = ref.watch(islandPreviewStyleProvider);
    final prosperity = ref.watch(islandPreviewProsperityProvider);
    final previewIsland = IslandState(
      shapeKey: style.shapeKey,
      style: style.style,
      elevation: style.elevation,
      prosperityTier: prosperity,
      radius: IslandVisualConfig.homeStoryPreviewRadius,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final asset = StoryIslandBuildingIcon.worldMapPreviewAsset(
      categoryId: island.categoryId,
      island: island,
    );
    final cacheW = (width * dpr).round().clamp(64, 512);
    // 副岛建筑略放大，居中落在岛面中部。
    final buildingHeight = height * 0.40;
    final buildingWidth = width * 0.52;
    final buildingTop = height * 0.54 - buildingHeight * 0.72;

    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: WorldPreviewCamera.islandTransform(),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            IslandBodyView(
              island: previewIsland,
              environment: style.environment,
              width: width,
              height: height,
            ),
            Positioned(
              left: (width - buildingWidth) / 2,
              top: buildingTop,
              width: buildingWidth,
              height: buildingHeight,
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

