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
  });

  final bool compact;
  final double time;
  final MoodEnvironmentState environment;
  final LawnRenderPass pass;
  final LawnObstacleMask? obstacleMask;
  final Path? clipPath;

  void paint(Canvas canvas, Size size, IslandState island) {
    final islandScale = island.radius.clamp(0.85, 1.25);
    final center = IslandPlacement.pixelCenter(size, compact: compact);
    final radius =
        IslandPlacement.pixelRadius(size, compact: compact) * islandScale;

    RealisticLawnRenderer(
      compact: compact,
      time: time,
      environment: environment,
      sceneSize: size,
      pass: pass,
      obstacleMask: obstacleMask,
      clipPath: clipPath,
    ).paint(
      canvas,
      style: island.style,
      cx: center.dx,
      cy: center.dy,
      rx: radius,
      ry: radius,
    );
  }
}
