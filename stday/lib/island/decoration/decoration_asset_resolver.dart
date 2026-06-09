import 'dart:ui' as ui;

import 'package:flame/game.dart';

import '../../world/engine/world_state.dart';

class DecorationAsset {
  const DecorationAsset({
    this.image,
    this.region,
    this.requestedPath,
  });

  final ui.Image? image;
  final ui.Rect? region;
  final String? requestedPath;

  bool get hasImage => image != null && region != null;
}

class DecorationAssetResolver {
  final Map<String, DecorationAsset> _cache = {};

  Future<void> preload(
    FlameGame game,
    Iterable<DecorationSnapshot> decorations,
  ) async {
    for (final decoration in decorations) {
      await resolve(game, decoration);
    }
  }

  Future<DecorationAsset> resolve(
    FlameGame game,
    DecorationSnapshot decoration,
  ) async {
    final cached = _cache[decoration.configId];
    if (cached != null) return cached;

    try {
      final image = await game.images.load(decoration.asset);
      final asset = DecorationAsset(
        image: image,
        requestedPath: decoration.asset,
        region: ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
      _cache[decoration.configId] = asset;
      return asset;
    } catch (_) {
      const fallback = DecorationAsset();
      _cache[decoration.configId] = fallback;
      return fallback;
    }
  }

  DecorationAsset cachedOrFallback(DecorationSnapshot decoration) {
    return _cache[decoration.configId] ?? const DecorationAsset();
  }
}
