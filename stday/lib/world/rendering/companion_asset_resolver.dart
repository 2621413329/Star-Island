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
    final cacheKey = _cacheKey(gender: gender, expression: expression);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    for (final path in companionBaseAssetCandidates(
      gender: gender,
      assetId: expression,
    )) {
      final flamePath = _toFlameImagePath(path);
      final asset = await _tryLoad(game, flamePath);
      if (asset.hasImage) {
        _cache[cacheKey] = asset;
        return asset;
      }
    }
    const fallback = CompanionImageAsset();
    _cache[cacheKey] = fallback;
    return fallback;
  }

  Future<CompanionImageAsset> resolveProp(FlameGame game, String prop) async {
    final catalog = await CompanionPropAssetCatalog.load();
    final assetPath = catalog.resolve(prop);
    final flamePath = _toFlameImagePath(assetPath);
    _resolvedPropPaths[prop] = flamePath;
    final cached = _cache[flamePath];
    if (cached != null) return cached;
    final asset = await _tryLoad(game, flamePath);
    _cache[flamePath] = asset;
    return asset;
  }

  CompanionImageAsset cachedBase({
    required String? gender,
    required String expression,
  }) {
    return _cache[_cacheKey(gender: gender, expression: expression)] ??
        const CompanionImageAsset();
  }

  CompanionImageAsset cachedProp(String prop) {
    return _cache[_resolvedPropPaths[prop] ?? _propPath(prop)] ??
        const CompanionImageAsset();
  }

  Future<CompanionImageAsset> _tryLoad(FlameGame game, String path) async {
    try {
      final image = await game.images.load(path);
      return CompanionImageAsset(
        image: image,
        region: ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
    } catch (_) {
      return const CompanionImageAsset();
    }
  }

  static String _cacheKey({
    required String? gender,
    required String expression,
  }) =>
      '${gender ?? ''}|${companionBaseAssetId(expression)}';

  static String _propPath(String prop) => 'companion/props/$prop.png';

  static String _toFlameImagePath(String assetPath) {
    const imageRoot = 'assets/images/';
    return assetPath.startsWith(imageRoot)
        ? assetPath.substring(imageRoot.length)
        : assetPath;
  }
}
