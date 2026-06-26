import 'dart:ui';

import '../../engine/world_state.dart';
import '../../island/growth_world_ground_painter.dart';
import '../../island/island_shape_profile.dart';
import '../../island/lawn_obstacle_mask.dart';
import '../../../island/decor/decor_placement_resolver.dart';
import '../../../island/config/island_visual_config.dart';
import '../../../island/decor/decor_config.dart';
import 'world_layer.dart';

/// 前景草层：在建筑/装饰之上、角色之下，局部遮挡障碍物。
class ForegroundGrassLayer extends WorldLayer {
  ForegroundGrassLayer({required this.compact}) : super(layerPriority: 580);

  final bool compact;
  double _time = 0;
  Map<String, Offset> _decorPositions = const {};

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void onWorldStateChanged(WorldState worldState) {
    final level =
        worldState.characters.isEmpty ? 1 : worldState.characters.first.level;
    _decorPositions = const DecorPlacementResolver()
        .resolve(DecorConfigs.unlockedAt(level));
  }

  @override
  void render(Canvas canvas) {
    if (!isMounted) return;
    if (state.island.style.biome != 'growth_world') return;
    final s = sceneSize;
    final size = Size(s.x, s.y);
    final profile = IslandShapeProfile.resolve(state.island.style);
    final clipPath = profile.buildInsetPath(
      size,
      compact: compact,
      inset: IslandVisualConfig.growthStoneBandInset,
      islandRadius: state.island.radius,
    );
    final mask = LawnObstacleMask.fromWorldState(
      state,
      sceneHeight: s.y,
      decorPositionOverrides: _decorPositions,
    );

    canvas.save();
    canvas.clipPath(clipPath);
    GrowthWorldGroundPainter(
      compact: compact,
      time: _time,
      environment: state.environment,
      pass: LawnRenderPass.foreground,
      obstacleMask: mask,
      clipPath: clipPath,
      animateGrass: false,
    ).paint(canvas, size, state.island);
    canvas.restore();
  }
}
