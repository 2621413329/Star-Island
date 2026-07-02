import 'package:flutter/material.dart';

import '../../../island/viewport/growth_world_viewport.dart';
import '../../../world/preview/world_preview_camera.dart';
import '../../../world/preview/world_preview_performance.dart';

/// 中央主岛视口（38° 俯视）。
class WorldPreviewMainIsland extends StatelessWidget {
  const WorldPreviewMainIsland({
    super.key,
    required this.width,
    required this.height,
    required this.enginePaused,
    required this.quality,
  });

  final double width;
  final double height;
  final bool enginePaused;
  final WorldPreviewQuality quality;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Transform(
          alignment: Alignment.center,
          transform: WorldPreviewCamera.islandTransform(),
          child: GrowthWorldViewport(
            useIslandWorldProvider: true,
            compact: true,
            interactive: false,
            enginePaused: enginePaused,
            previewZoom:
                WorldPreviewPerformance.mainIslandPreviewZoom(quality),
            islandOnly: true,
            enableDecor:
                WorldPreviewPerformance.enableMainIslandDecor(quality),
          ),
        ),
      ),
    );
  }
}
