import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/mood_island_config.dart';
import '../../world/engine/world_state.dart';
import 'island_world_provider.dart';

/// 首页岛体实际会画出来的样式。繁荣等级单独订阅，避免主岛跟着副岛繁荣刷新。
class IslandPreviewStyle {
  IslandPreviewStyle._(
    this.signature,
    this.shapeKey,
    this.style,
    this.elevation,
    this.environment,
  );

  final String signature;
  final String shapeKey;
  final MoodIslandConfig style;
  final double elevation;
  final MoodEnvironmentState environment;

  factory IslandPreviewStyle.capture(WorldState state) {
    final island = state.island;
    final style = island.style;
    final env = state.environment;
    final signature = [
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
    ].join('|');
    return IslandPreviewStyle._(
      signature,
      island.shapeKey,
      style,
      island.elevation,
      env,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IslandPreviewStyle && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}

final islandPreviewStyleProvider = Provider<IslandPreviewStyle>((ref) {
  final state = ref.watch(islandWorldPreviewProvider);
  return IslandPreviewStyle.capture(state);
});

/// 副岛岛体繁荣。主岛预览固定用低档繁荣，不订阅这项。
final islandPreviewProsperityProvider = Provider<int>((ref) {
  return ref.watch(islandWorldPreviewProvider).island.prosperityTier;
});

/// 主岛小人落点。位置不变时不通知。
final islandPreviewCharacterOffsetProvider = Provider<Offset?>((ref) {
  final state = ref.watch(islandWorldPreviewProvider);
  if (state.characters.isEmpty) return null;
  final position = state.characters.first.normalizedPos;
  return Offset(
    (position.dx * 1000).round() / 1000,
    (position.dy * 1000).round() / 1000,
  );
});
