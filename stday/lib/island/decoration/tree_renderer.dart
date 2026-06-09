import 'dart:ui';

import '../../world/rendering/cozy_tree_renderer.dart';

class TreeRenderer {
  const TreeRenderer();

  void render(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required double wind,
    required double time,
    required String asset,
  }) {
    if (asset.contains('pine')) {
      CozyTreeRenderer.drawPine(canvas, base, scale, wind, time);
      return;
    }
    CozyTreeRenderer.drawPuffy(canvas, base, scale, wind, time);
  }
}
