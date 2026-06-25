import 'dart:ui' as ui;

import 'package:flame/game.dart';

import '../../core/constants/companion_base_asset.dart';
import '../../design_system/companion_prop_asset_catalog.dart';

class CompanionImageAsset {
  const CompanionImageAsset({
    this.image,
    this.region,
  });

  final ui.Image? image;
  final ui.Rect? region;

  bool get hasImage => image != null && region != null;
}

class CompanionAssetResolver {
  final Map<String, CompanionImageAsset> _cache = {};
  final Map<String, String> _resolvedPropPaths = {};

  Future<void> preload(
    FlameGame game, {
    required String? gender,
    required Iterable<String> expressions,
    required Iterable<String> props,
  }) async {
    for (final expression in expressions) {
      await resolveBase(game, gender: gender, expression: expression);
    }
    for (final prop in props) {
      if (prop == 'none') continue;
      await resolveProp(game, prop);
    }
  }

  Future<CompanionImageAsset> resolveBase(
    FlameGame game, {
    required String? gender,
    required String expression,
  }) async {
    final path = _basePath(gender: gender, expression: expression);
    return _resolve(game, path, gender: gender);
  }

  Future<CompanionImageAsset> resolveProp(FlameGame game, String prop) async {
    final catalog = await CompanionPropAssetCatalog.load();
    final assetPath = catalog.resolve(prop);
    final flamePath = _toFlameImagePath(assetPath);
    _resolvedPropPaths[prop] = flamePath;
    return _resolve(game, flamePath);
  }

  CompanionImageAsset cachedBase({
    required String? gender,
    required String expression,
  }) {
    return _cache[_basePath(gender: gender, expression: expression)] ??
        const CompanionImageAsset();
  }

  CompanionImageAsset cachedProp(String prop) {
    return _cache[_resolvedPropPaths[prop] ?? _propPath(prop)] ??
        const CompanionImageAsset();
  }

  Future<CompanionImageAsset> _resolve(
    FlameGame game,
    String path, {
    String? gender,
  }) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      final image = await game.images.load(path);
      final asset = CompanionImageAsset(
        image: image,
        region: ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
      _cache[path] = asset;
      return asset;
    } catch (_) {
      final placeholderPath = _basePath(
        gender: gender,
        expression: companionBasePlaceholderId,
      );
      if (path != placeholderPath) {
        try {
          final image = await game.images.load(placeholderPath);
          final asset = CompanionImageAsset(
            image: image,
            region: ui.Rect.fromLTWH(
              0,
              0,
              image.width.toDouble(),
              image.height.toDouble(),
            ),
          );
          _cache[path] = asset;
          return asset;
        } catch (_) {}
      }
      const fallback = CompanionImageAsset();
      _cache[path] = fallback;
      return fallback;
    }
  }

  static String _basePath({
    required String? gender,
    required String expression,
  }) =>
      companionBaseFlameAssetPath(gender: gender, assetId: expression);

  static String _propPath(String prop) => 'companion/props/$prop.png';

  static String _toFlameImagePath(String assetPath) {
    const imageRoot = 'assets/images/';
    return assetPath.startsWith(imageRoot)
        ? assetPath.substring(imageRoot.length)
        : assetPath;
  }
}
