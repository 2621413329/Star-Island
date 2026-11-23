import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_footprint.dart';
import '../../island/building/building_sprite_metrics.dart';
import '../island/painted_island_asset.dart';

/// 主岛建筑立面尺寸。高度按岛面比例，不同建筑用各自的内容占比，避免都变成一样大的方块。
({double width, double height}) mainIslandBuildingSpriteSize({
  required String definitionId,
  required Size sceneSize,
  required double imageAspect,
  double renderScale = 1,
  double plateScale = 1,
}) {
  final fitted = plateScale.clamp(1.0, 1.45);
  final plate = PaintedIslandAsset.layoutRect(sceneSize, scale: fitted);
  final boost = BuildingFootprint.visualRenderBoostFor(definitionId);
  final depth = (renderScale / boost).clamp(0.75, 1.25);
  final role = switch (definitionId) {
    'growth_academy' => 0.30,
    'lighthouse' ||
    'lighthouse_base' ||
    'growth_clocktower' ||
    'dream_observatory' =>
      0.26,
    'growth_tree' => 0.20,
    'harbor_pier' => 0.12,
    'story_plaza' ||
    'companion_plaza' ||
    'starter_stone' ||
    'habit_flowerbed' =>
      0.10,
    _ => 0.17,
  };
  final fill =
      BuildingSpriteMetrics.verticalFillRatio(definitionId).clamp(0.25, 1.0);
  final height = plate.height * role * depth / fill;
  final aspect = imageAspect > 0 ? imageAspect : 1.0;
  return (width: height * aspect, height: height);
}

/// 主岛建筑在画面上的立面矩形，和 [BuildingLayer] 画上去的方图重合。
///
/// 素材是正方形画布，脚点对齐底边。热区用整张立面，避免放大后屋顶点不中。
Rect mainIslandBuildingTapRect({
  required String definitionId,
  required Offset plateAnchor,
  required Size sceneSize,
  double jumpOffsetY = 0,
  double popScale = 1,
  double plateScale = 1,
}) {
  final sceneScale = (sceneSize.width / 390).clamp(0.85, 1.15);
  var renderScale = sceneScale *
      BuildingDepthScale.forAnchorDy(plateAnchor.dy) *
      popScale;
  if (definitionId == 'growth_academy') {
    renderScale *= BuildingFootprint.academyVisualRenderBoost;
  } else if (definitionId == 'harbor_pier') {
    renderScale *= BuildingFootprint.pierVisualRenderBoost;
  }
  final fitted = plateScale.clamp(1.0, 1.45);
  final drawn = mainIslandBuildingSpriteSize(
    definitionId: definitionId,
    sceneSize: sceneSize,
    imageAspect: 1,
    renderScale: renderScale,
    plateScale: fitted,
  );
  final foot = PaintedIslandAsset.plateToCanvas(
    plateAnchor,
    sceneSize,
    scale: fitted,
  );
  return Rect.fromLTWH(
    foot.dx - drawn.width / 2,
    foot.dy - drawn.height + jumpOffsetY,
    drawn.width,
    drawn.height,
  );
}
