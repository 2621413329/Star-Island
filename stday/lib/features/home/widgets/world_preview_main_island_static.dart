import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../island/providers/island_world_provider.dart';
import '../../../world/engine/world_state.dart';
import '../../../world/island/island_renderer.dart';
import '../../../world/preview/world_preview_camera.dart';

/// 首页主岛纯 Canvas 静态预览（无 Flame），优先流畅。
class WorldPreviewMainIslandStatic extends ConsumerWidget {
  const WorldPreviewMainIslandStatic({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(islandWorldPreviewProvider);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: CustomPaint(
            size: Size(width, height),
            painter: _MainIslandPreviewPainter(
              island: base.island,
              environment: base.environment,
            ),
          ),
        ),
      ),
    );
  }
}

class _MainIslandPreviewPainter extends CustomPainter {
  _MainIslandPreviewPainter({
    required this.island,
    required this.environment,
  });

  final IslandState island;
  final MoodEnvironmentState environment;

  static final _renderer = IslandRenderer(compact: true);

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, size, island, environment);
  }

  @override
  bool shouldRepaint(covariant _MainIslandPreviewPainter oldDelegate) {
    return oldDelegate.island.radius != island.radius ||
        oldDelegate.island.prosperityTier != island.prosperityTier;
  }
}
