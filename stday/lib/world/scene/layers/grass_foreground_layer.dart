import 'dart:ui';

import '../../../common/island_contracts/decor_config.dart';
import '../../../common/island_contracts/grass_skirt_painter.dart';
import '../../../common/island_contracts/growth_island_configs.dart';
import '../../engine/world_state.dart';
import '../../island/island_placement.dart';
import '../../island/island_shape_profile.dart';
import '../../island/island_visual_config.dart';
import 'world_layer.dart';

/// 前景草层：画在地面装饰与建筑之上、角色之下，根部草叶略微遮挡装饰底部。
class GrassForegroundLayer extends WorldLayer {
  GrassForegroundLayer({required this.compact}) : super(layerPriority: 580);

  final bool compact;
  int _userLevel = 1;

  @override
  void onWorldStateChanged(WorldState worldState) {
    _userLevel =
        worldState.characters.isEmpty ? 1 : worldState.characters.first.level;
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    if (state.island.style.biome != 'growth_world') return;

    final s = sceneSize;
    final size = Size(s.x, s.y);
    final style = state.island.style;
    final islandScale = state.island.radius.clamp(0.85, 3.5);
    final cx = s.x * 0.5;
    final cy = s.y * (compact ? 0.56 : 0.54);
    final compactScale = compact ? 1.414 : 1.0;
    final rx = s.x *
        IslandPlacement.growthRadiusX *
        (compact ? 0.952 : 1.0) *
        compactScale *
        islandScale *
        0.88;
    final ry = s.y *
        IslandPlacement.growthRadiusY *
        (compact ? 1.19 : 1.0) *
        compactScale *
        islandScale;

    final profile = IslandShapeProfile.resolve(style);
    final clipPath = profile.buildInsetPath(
      size,
      compact: compact,
      inset: IslandVisualConfig.growthStoneBandInset,
      islandRadius: state.island.radius,
    );
    canvas.save();
    canvas.clipPath(clipPath);

    GrassSkirtPainter.drawForegroundBand(
      canvas,
      cx: cx,
      cy: cy,
      rx: rx,
      ry: ry,
      grass: style.grass,
      time: 0,
    );

    _drawDecorSkirts(canvas, s.x, s.y, style.grass);
    _drawBuildingSkirts(canvas, s.x, s.y, style.grass);
    canvas.restore();
  }

  void _drawDecorSkirts(Canvas canvas, double vw, double vh, Color grass) {
    final unlocked = DecorConfigs.unlockedAt(_userLevel);
    for (final config in unlocked) {
      if (!GrassSkirtPainter.isGroundDecorCategory(config.category.name)) {
        continue;
      }
      final anchor = Offset(config.x * vw, config.y * vh);
      if (!IslandPlacement.isOnGrowthIsland(
        Offset(anchor.dx / vw, anchor.dy / vh),
        inset: 0.96,
      )) {
        continue;
      }
      final approxWidth = vw * 0.07 * config.scale * config.randomScale;
      final coverHeight = approxWidth * _coverRatioForCategory(config.category);
      GrassSkirtPainter.drawAtAnchor(
        canvas,
        anchor: anchor,
        width: approxWidth,
        coverHeight: coverHeight,
        grass: grass,
        time: 0,
        seed: config.id.hashCode,
        density: _densityForCategory(config.category),
      );
    }
  }

  void _drawBuildingSkirts(Canvas canvas, double vw, double vh, Color grass) {
    final scale = (vw / 390).clamp(0.85, 1.15).toDouble();
    for (final building in state.buildings) {
      final anchor = Offset(building.anchor.dx * vw, building.anchor.dy * vh);
      if (!IslandPlacement.isOnGrowthIsland(building.anchor, inset: 0.96)) {
        continue;
      }
      final configured =
          GrowthIslandConfigs.buildingById(building.definitionId);
      final footprint = building.size;
      final width = (footprint.dx * 320 * scale).clamp(36.0, 160.0);
      final height = (footprint.dy * 280 * scale).clamp(32.0, 140.0);
      final coverHeight = height * (configured?.type == 'house' ? 0.16 : 0.20);
      GrassSkirtPainter.drawAtAnchor(
        canvas,
        anchor: anchor,
        width: width,
        coverHeight: coverHeight,
        grass: grass,
        time: 0,
        seed: building.definitionId.hashCode,
        density: 1.15,
      );
    }
  }

  double _coverRatioForCategory(DecorCategory category) {
    return switch (category) {
      DecorCategory.grass => 0.14,
      DecorCategory.flower => 0.22,
      DecorCategory.stone => 0.12,
      DecorCategory.bush => 0.24,
      DecorCategory.tree => 0.18,
      DecorCategory.pond => 0.10,
      DecorCategory.special => 0.20,
      _ => 0.16,
    };
  }

  double _densityForCategory(DecorCategory category) {
    return switch (category) {
      DecorCategory.tree => 0.9,
      DecorCategory.bush => 1.0,
      DecorCategory.flower => 1.2,
      DecorCategory.stone => 0.85,
      _ => 1.0,
    };
  }
}
