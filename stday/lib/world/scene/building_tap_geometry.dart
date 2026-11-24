import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_footprint.dart';
import '../island/detail_building_spread.dart';
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
  // 学院/栈桥的渲染倍率已经乘进 renderScale，这里除回去，避免再放大一轮。
  final depth = (renderScale / boost).clamp(0.82, 1.18);
  // 立面高度直接占岛面比例，不再除以内容填充率。
  // 填充率把广场（约 0.28）放大成比房子还高的块，灯塔和民居又挤成差不多高。
  // 高度按岛面比例封顶，让相邻坑位的立面不会互相盖住。
  final role = switch (definitionId) {
    'lighthouse' => 0.30,
    'growth_clocktower' => 0.26,
    'dream_observatory' || 'memory_gallery' => 0.24,
    'growth_academy' => 0.28,
    'lighthouse_base' => 0.22,
    'growth_tree' => 0.22,
    'growth_house_lv2' => 0.24,
    'growth_house' || 'library_seed' => 0.22,
    'memory_fountain' => 0.16,
    'emotion_windchime' => 0.18,
    'record_shed' || 'quiet_tent' => 0.18,
    'memory_mailbox' => 0.14,
    'harbor_pier' => 0.16,
    'starter_stone' => 0.12,
    'habit_flowerbed' => 0.14,
    'story_plaza' || 'companion_plaza' => 0.10,
    _ => 0.20,
  };
  final height =
      (plate.height * role * depth).clamp(0.0, plate.height * 0.50);
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
  final fitted = plateScale.clamp(1.0, 1.45);
  final placed =
      DetailBuildingSpread.place(definitionId, plateAnchor, fitted);
  final sceneScale = (sceneSize.width / 390).clamp(0.85, 1.15);
  var renderScale = sceneScale *
      BuildingDepthScale.forAnchorDy(placed.dy) *
      popScale;
  if (definitionId == 'growth_academy') {
    renderScale *= BuildingFootprint.academyVisualRenderBoost;
  } else if (definitionId == 'harbor_pier') {
    renderScale *= BuildingFootprint.pierVisualRenderBoost;
  }
  final drawn = mainIslandBuildingSpriteSize(
    definitionId: definitionId,
    sceneSize: sceneSize,
    imageAspect: 1,
    renderScale: renderScale,
    plateScale: fitted,
  );
  final foot = PaintedIslandAsset.plateToCanvas(
    placed,
    sceneSize,
    scale: fitted,
  );
  final sink = drawn.height * BuildingSpriteMetrics.baselineInset(definitionId);
  return Rect.fromLTWH(
    foot.dx - drawn.width / 2,
    foot.dy - drawn.height + sink + jumpOffsetY,
    drawn.width,
    drawn.height,
  );
}
