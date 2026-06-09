import 'dart:ui';

import '../../world/engine/world_state.dart';
import 'flower_renderer.dart';
import 'grass_renderer.dart';
import 'rock_renderer.dart';
import 'tree_renderer.dart';

class DecorationRenderer {
  const DecorationRenderer({
    this.grassRenderer = const GrassRenderer(),
    this.flowerRenderer = const FlowerRenderer(),
    this.treeRenderer = const TreeRenderer(),
    this.rockRenderer = const RockRenderer(),
  });

  final GrassRenderer grassRenderer;
  final FlowerRenderer flowerRenderer;
  final TreeRenderer treeRenderer;
  final RockRenderer rockRenderer;

  void render(
    Canvas canvas, {
    required DecorationSnapshot decoration,
    required Offset base,
    required double wind,
    required double time,
    required Color flowerColor,
  }) {
    switch (decoration.type) {
      case 'grass':
        grassRenderer.render(
          canvas,
          base: base,
          scale: decoration.scale,
          wind: wind,
          time: time,
        );
      case 'flower':
        flowerRenderer.render(
          canvas,
          base: base,
          scale: decoration.scale,
          color: flowerColor,
          time: time,
        );
      case 'tree':
        treeRenderer.render(
          canvas,
          base: base,
          scale: decoration.scale,
          wind: wind,
          time: time,
          asset: decoration.asset,
        );
      case 'bush':
      default:
        rockRenderer.render(
          canvas,
          base: base,
          scale: decoration.scale,
          rotation: decoration.rotation,
        );
    }
  }
}
