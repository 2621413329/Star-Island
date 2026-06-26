import 'dart:ui';

import '../../island/placement/island_placement.dart';
import '../engine/world_state.dart';
import 'lawn_obstacle_mask.dart';
import 'realistic_lawn_renderer.dart';

/// Growth Island 2.0 平地草坪：程序化写实草簇渲染，严格限制在石质边缘以内。
class GrowthWorldGroundPainter {
  const GrowthWorldGroundPainter({
    required this.compact,
    required this.time,
    required this.environment,
    this.pass = LawnRenderPass.background,
    this.obstacleMask,
    this.clipPath,
    this.animateGrass = false,
  });

  final bool compact;
  final double time;
  final MoodEnvironmentState environment;
  final LawnRenderPass pass;
  final LawnObstacleMask? obstacleMask;
  final Path? clipPath;
  final bool animateGrass;

  void paint(Canvas canvas, Size size, IslandState island) {
    final islandScale = island.radius.clamp(0.85, 3.5);
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.56 : 0.54);
    final compactScale = compact ? 1.414 : 1.0;
    final rx = size.width *
        IslandPlacement.growthRadiusX *
        (compact ? 0.952 : 1.0) *
        compactScale *
        islandScale;
    final ry = size.height *
        IslandPlacement.growthRadiusY *
        (compact ? 1.19 : 1.0) *
        compactScale *
        islandScale;

    RealisticLawnRenderer(
      compact: compact,
      time: animateGrass ? time : 0,
      environment: environment,
      sceneSize: size,
      pass: pass,
      obstacleMask: obstacleMask,
      clipPath: clipPath,
      animateGrass: animateGrass,
    ).paint(
      canvas,
      style: island.style,
      cx: cx,
      cy: cy,
      rx: rx,
      ry: ry,
    );
  }
}
