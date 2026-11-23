import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/story_island_models.dart';
import '../../../island/providers/island_preview_body.dart';
import '../../island/widgets/story_island_theme_layer.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_body_image_cache.dart';
import '../../../world/island/island_visual_config.dart';
import '../../../world/island/painted_island_asset.dart';
import '../../../world/island/painted_island_pits.dart';
import '../../../world/preview/story_island_building_icon.dart';

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
      plateKey: island.categoryId,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final asset = StoryIslandBuildingIcon.worldMapPreviewAsset(
      categoryId: island.categoryId,
      island: island,
    );
    final viewport = Size(width, height);
    final plate = PaintedIslandAsset.layoutRect(viewport);
    final level = StoryIslandBuildingIcon.worldMapPreviewBuildingLevel(island);
    final foot = PaintedIslandAsset.plateToCanvas(
      PaintedIslandPits.storyBuilding(level),
      viewport,
    );
    // 素材几乎铺满画布。0.34 会让健康岛的树、工作岛的房子盖住整座岛。
    final buildingHeight = plate.height * 0.16;
    final buildingWidth = buildingHeight * 0.92;
    final cacheW = (buildingWidth * dpr).round().clamp(48, 256);

    return SizedBox(
      width: width,
      height: height,
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
          StoryIslandThemeLayer(
            categoryId: island.categoryId,
            viewportSize: viewport,
          ),
          Positioned(
            left: foot.dx - buildingWidth / 2,
            top: foot.dy - buildingHeight,
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
    );
  }
}
