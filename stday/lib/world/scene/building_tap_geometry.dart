import 'dart:ui';

import '../../island/building/building_depth_scale.dart';
import '../../island/building/building_footprint.dart';
import '../island/painted_island_asset.dart';

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
  final plate = PaintedIslandAsset.layoutRect(sceneSize, scale: fitted);
  final heightFactor = switch (definitionId) {
    'growth_tree' => 0.24,
    'growth_academy' || 'growth_clocktower' || 'lighthouse' => 0.21,
    _ => 0.16,
  };
  // 岛坯放大后，立面像素保持原尺寸，多出来的是地面。
  final drawnHeight = plate.height *
      heightFactor *
      renderScale.clamp(0.7, 1.35) /
      fitted;
  // 建筑 PNG 是正方形画布，绘制宽度等于高度。
  final drawnWidth = drawnHeight;
  final foot = PaintedIslandAsset.plateToCanvas(
    plateAnchor,
    sceneSize,
    scale: fitted,
  );
  // 与 _drawPlateSprite 的目标矩形一致：底边对齐脚点，宽高等于画出的整张图。
  return Rect.fromLTWH(
    foot.dx - drawnWidth / 2,
    foot.dy - drawnHeight + jumpOffsetY,
    drawnWidth,
    drawnHeight,
  );
}
