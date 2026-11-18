import 'dart:ui';

import '../engine/world_state.dart';

/// 岛体外观缓存键。尺寸、繁荣、主题色和环境光照任一变化都会换成新键。
class IslandRenderKey {
  IslandRenderKey._(this.cacheKey);

  final String cacheKey;

  factory IslandRenderKey.from({
    required bool compact,
    required Size size,
    required IslandState island,
    required MoodEnvironmentState environment,
  }) {
    final style = island.style;
    final env = environment;
    return IslandRenderKey._([
      compact ? 'c' : 'f',
      size.width.round(),
      size.height.round(),
      island.shapeKey,
      style.styleKey,
      style.islandShape,
      style.moodId,
      style.grass.toARGB32(),
      style.sand.toARGB32(),
      style.sea.toARGB32(),
      style.accent.toARGB32(),
      style.flower.toARGB32(),
      (island.elevation * 1000).round(),
      island.prosperityTier,
      (island.radius * 1000).round(),
      env.sea.toARGB32(),
      (env.sunX * 1000).round(),
      (env.sunY * 1000).round(),
      (env.sunIntensity * 1000).round(),
      (env.windStrength * 1000).round(),
      (env.lightWarmth * 1000).round(),
      (env.ambientShadeStrength * 1000).round(),
      (env.shadowDx * 1000).round(),
      (env.shadowDy * 1000).round(),
      (env.shadowStretch * 1000).round(),
      (env.shadowAlpha * 1000).round(),
    ].join('|'));
  }

  /// 同一外观在不同像素密度下各存一张位图，避免低清图被放大。
  String imageKey({required int pixelWidth, required int pixelHeight}) =>
      '$cacheKey@${pixelWidth}x$pixelHeight';

  @override
  bool operator ==(Object other) =>
      other is IslandRenderKey && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}
