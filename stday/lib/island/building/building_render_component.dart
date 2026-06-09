import 'dart:ui';

import '../../core/models/mood_island_config.dart';
import '../../world/engine/world_state.dart';
import '../config/growth_island_config_models.dart';
import 'building_asset_resolver.dart';
import 'procedural_building_renderer.dart';

class BuildingRenderComponent {
  BuildingRenderComponent({
    required this.config,
    required this.snapshot,
    required this.asset,
    this.proceduralRenderer = const ProceduralBuildingRenderer(),
  });

  final BuildingConfig config;
  final BuildingSnapshot snapshot;
  final BuildingAsset asset;
  final ProceduralBuildingRenderer proceduralRenderer;

  void render(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required MoodIslandConfig style,
  }) {
    _drawGroundShadow(canvas, base, scale);
    if (asset.hasImage) {
      _renderImage(canvas, base, scale);
      return;
    }
    proceduralRenderer.render(
      canvas,
      config: config,
      base: base,
      scale: scale,
      accent: style.accent,
      sea: style.sea,
      grass: style.grass,
      sand: style.sand,
    );
  }

  void _renderImage(Canvas canvas, Offset base, double scale) {
    final image = asset.image;
    final src = asset.region;
    if (image == null || src == null) return;

    final width = config.size.dx * 320 * scale;
    final height = config.size.dy * 280 * scale;
    final dst = Rect.fromCenter(
      center: base + Offset(0, -height * 0.42),
      width: width,
      height: height,
    );
    canvas.drawImageRect(image, src, dst, Paint());
  }

  void _drawGroundShadow(Canvas canvas, Offset base, double scale) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0, 5 * scale),
        width: config.size.dx * 280 * scale,
        height: config.size.dy * 58 * scale,
      ),
      Paint()..color = const Color(0xFF203F4A).withValues(alpha: 0.14),
    );
  }
}
