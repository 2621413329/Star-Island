import 'dart:ui';

import '../../core/models/mood_island_config.dart';
import '../../world/engine/world_state.dart';
import '../config/growth_island_config_models.dart';
import '../decor/decor_scale_resolver.dart';
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
    required double viewportHeight,
  }) {
    final renderBase = _renderBase(base, scale, viewportHeight);
    if (asset.hasImage) {
      _renderImage(canvas, renderBase, scale, viewportHeight);
      return;
    }
    proceduralRenderer.render(
      canvas,
      config: config,
      base: renderBase,
      scale: _cappedScale(scale, viewportHeight),
      accent: style.accent,
      sea: style.sea,
      grass: style.grass,
      sand: style.sand,
    );
  }

  Offset _renderBase(Offset base, double scale, double viewportHeight) {
    if (config.id != 'growth_academy') return base;
    final cappedScale = _cappedScale(scale, viewportHeight);
    final halfImage = snapshot.size.dy * 280 * cappedScale * 0.5;
    return base + Offset(0, halfImage);
  }

  double _cappedScale(double scale, double viewportHeight) {
    final footprint = snapshot.size;
    final rawHeight = footprint.dy * 280 * scale;
    final cap = DecorScaleResolver.clampBuildingScale(
      height: rawHeight,
      viewportHeight: viewportHeight,
    );
    return scale * cap;
  }

  void _renderImage(
      Canvas canvas, Offset base, double scale, double viewportHeight) {
    final image = asset.image;
    final src = asset.region;
    if (image == null || src == null) return;

    final footprint = snapshot.size;
    final cappedScale = _cappedScale(scale, viewportHeight);
    final imageAspect = src.width / src.height;
    final height = footprint.dy * 280 * cappedScale;
    final width = height * imageAspect;
    final dst = _grassAlignedRect(base, width, height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  Rect _grassAlignedRect(Offset base, double width, double height) {
    final pad = switch (config.type) {
      'stone' || 'mailbox' || 'windchime' => 0.08,
      'house' || 'shed' || 'tent' => 0.12,
      'academy' => 0.10,
      'lighthouse' || 'clocktower' || 'observatory' => 0.11,
      _ => 0.10,
    };
    return Rect.fromLTWH(
      base.dx - width / 2,
      base.dy - height * (1 - pad),
      width,
      height,
    );
  }
}
