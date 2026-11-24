import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_footprint.dart';
import '../../island/building/building_sprite_metrics.dart';
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
  // 高度按岛坯比例。灯塔窄而高，房子中等，广场贴地。相邻坑位因此留得出草地。
  final role = DetailBuildingSpread.roleFor(definitionId);
  final height =
      (plate.height * role * depth).clamp(0.0, plate.height * 0.42);
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
