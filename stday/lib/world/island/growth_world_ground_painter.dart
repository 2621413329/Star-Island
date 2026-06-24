import 'dart:ui';

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
    final style = island.style;
    final islandScale = island.radius.clamp(0.85, 1.25);
    final cx = size.width * 0.5;
    final cy = size.height * (compact ? 0.56 : 0.54);
    final compactScale = compact ? 1.414 : 1.0;
    final rx = size.width *
        0.50 *
        (compact ? 0.952 : 1.0) *
        compactScale *
        islandScale *
        0.90;
    final ry = size.height *
        0.125 *
        (compact ? 1.19 : 1.0) *
        compactScale *
        islandScale *
        0.90;

    RealisticLawnRenderer(
      compact: compact,
      time: time,
      environment: environment,
      pass: pass,
      obstacleMask: obstacleMask,
      clipPath: clipPath,
      sceneSize: size,
    ).paint(
      canvas,
      style: style,
      cx: cx,
      cy: cy,
      rx: rx,
      ry: ry,
    );
  }
}
