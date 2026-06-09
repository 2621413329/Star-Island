import 'dart:ui' as ui;

import 'package:flame/game.dart';

import '../config/growth_island_config_models.dart';

enum BuildingAssetSource { atlas, sprite, procedural }

class BuildingAsset {
  const BuildingAsset({
    required this.source,
    this.image,
    this.region,
    this.requestedPath,
  });

  final BuildingAssetSource source;
  final ui.Image? image;
  final ui.Rect? region;
  final String? requestedPath;

  bool get hasImage => image != null;
}

class BuildingAssetResolver {
  BuildingAssetResolver();

  final Map<String, BuildingAsset> _cache = {};

  Future<BuildingAsset> resolve(
    FlameGame game,
    BuildingConfig config,
  ) async {
    final cached = _cache[config.id];
    if (cached != null) return cached;

    final atlasAsset = await _tryLoadAtlasRegion(game, config);
    if (atlasAsset != null) {
      _cache[config.id] = atlasAsset;
      return atlasAsset;
    }

    final spriteAsset = await _tryLoadSprite(game, config);
    if (spriteAsset != null) {
      _cache[config.id] = spriteAsset;
      return spriteAsset;
    }

    const fallback = BuildingAsset(source: BuildingAssetSource.procedural);
    _cache[config.id] = fallback;
    return fallback;
  }

  BuildingAsset cachedOrFallback(BuildingConfig config) {
    return _cache[config.id] ??
        const BuildingAsset(source: BuildingAssetSource.procedural);
  }

  Future<BuildingAsset?> _tryLoadAtlasRegion(
    FlameGame game,
    BuildingConfig config,
  ) async {
    if (!config.sprite.startsWith('atlas:')) return null;
    final ref = config.sprite.substring('atlas:'.length);
    final parts = ref.split('#');
    if (parts.length != 2) return null;

    try {
      final image = await game.images.load(parts.first);
      // Region metadata will be supplied by atlas JSON in the asset pipeline.
      // Until then, atlas refs safely use the full image.
      return BuildingAsset(
        source: BuildingAssetSource.atlas,
        image: image,
        requestedPath: parts.first,
        region: ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<BuildingAsset?> _tryLoadSprite(
    FlameGame game,
    BuildingConfig config,
  ) async {
    if (config.sprite.isEmpty || config.sprite.startsWith('atlas:')) {
      return null;
    }
    try {
      final image = await game.images.load(config.sprite);
      return BuildingAsset(
        source: BuildingAssetSource.sprite,
        image: image,
        requestedPath: config.sprite,
        region: ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
