import 'dart:ui';

import '../../island/config/island_visual_config.dart';
import '../../island/placement/island_placement.dart';

import '../engine/world_state.dart';

/// 根据成长等级生成「世界繁荣」植被与装饰，而非 mood 道具。

class ProsperitySystem {
  const ProsperitySystem();

  List<FloraSnapshot> resolveFlora({required int prosperityTier}) {
    final visualTier = prosperityTier.clamp(0, 5);

    final out = <FloraSnapshot>[
      // Visual Prototype 基础自然层：首屏即有树、石、草、花。
      const FloraSnapshot(
        floraId: 'pine_w',
        kind: FloraKind.tree,
        position: Offset(0.18, 0.53),
        growth: 0.78,
      ),
      const FloraSnapshot(
        floraId: 'puffy_e',
        kind: FloraKind.tree,
        position: Offset(0.80, 0.52),
        growth: 0.76,
      ),
      const FloraSnapshot(
        floraId: 'puffy_back_l',
        kind: FloraKind.tree,
        position: Offset(0.32, 0.45),
        growth: 0.68,
      ),
      const FloraSnapshot(
        floraId: 'pine_back_r',
        kind: FloraKind.tree,
        position: Offset(0.68, 0.45),
        growth: 0.66,
      ),
      const FloraSnapshot(
        floraId: 'rock_sw',
        kind: FloraKind.bush,
        position: Offset(0.29, 0.59),
        growth: 0.82,
      ),
      const FloraSnapshot(
        floraId: 'rock_se',
        kind: FloraKind.bush,
        position: Offset(0.72, 0.58),
        growth: 0.78,
      ),
      const FloraSnapshot(
        floraId: 'grass_w',
        kind: FloraKind.grass,
        position: Offset(0.25, 0.60),
        growth: 1,
      ),
      const FloraSnapshot(
        floraId: 'grass_e',
        kind: FloraKind.grass,
        position: Offset(0.75, 0.59),
        growth: 1,
      ),
      const FloraSnapshot(
        floraId: 'flower_front_l',
        kind: FloraKind.flower,
        position: Offset(0.39, 0.62),
        growth: 0.72,
      ),
      const FloraSnapshot(
        floraId: 'flower_front_r',
        kind: FloraKind.flower,
        position: Offset(0.61, 0.61),
        growth: 0.70,
      ),
    ];

    // 周边松树 + 阔叶树（参考图：树在岛缘，不在中心）

    if (visualTier >= 1) {
      out.addAll(const [
        FloraSnapshot(
          floraId: 'pine_far_w',
          kind: FloraKind.tree,
          position: Offset(0.20, 0.54),
          growth: 0.72,
        ),
        FloraSnapshot(
          floraId: 'puffy_far_e',
          kind: FloraKind.tree,
          position: Offset(0.80, 0.54),
          growth: 0.68,
        ),
      ]);
    }

    if (visualTier >= 2) {
      out.addAll(const [
        FloraSnapshot(
          floraId: 'rock_sw',
          kind: FloraKind.bush,
          position: Offset(0.30, 0.58),
          growth: 0.85,
        ),
        FloraSnapshot(
          floraId: 'rock_se',
          kind: FloraKind.bush,
          position: Offset(0.70, 0.57),
          growth: 0.8,
        ),
        FloraSnapshot(
          floraId: 'grass_w',
          kind: FloraKind.grass,
          position: Offset(0.26, 0.60),
          growth: 1,
        ),
      ]);
    }

    if (visualTier >= 3) {
      out.addAll(const [
        FloraSnapshot(
          floraId: 'pine_nw',
          kind: FloraKind.tree,
          position: Offset(0.34, 0.46),
          growth: 0.78,
        ),
        FloraSnapshot(
          floraId: 'puffy_ne',
          kind: FloraKind.tree,
          position: Offset(0.66, 0.46),
          growth: 0.74,
        ),
        FloraSnapshot(
          floraId: 'grass_e',
          kind: FloraKind.grass,
          position: Offset(0.74, 0.59),
          growth: 1,
        ),
      ]);
    }

    if (visualTier >= 4) {
      out.addAll(const [
        FloraSnapshot(
          floraId: 'pine_far',
          kind: FloraKind.tree,
          position: Offset(0.14, 0.50),
          growth: 0.82,
        ),
        FloraSnapshot(
          floraId: 'rock_n',
          kind: FloraKind.bush,
          position: Offset(0.52, 0.42),
          growth: 0.75,
        ),
      ]);
    }

    if (visualTier >= 5) {
      out.addAll(const [
        FloraSnapshot(
          floraId: 'puffy_far',
          kind: FloraKind.tree,
          position: Offset(0.86, 0.49),
          growth: 0.88,
        ),
        FloraSnapshot(
          floraId: 'grass_c',
          kind: FloraKind.grass,
          position: Offset(0.58, 0.60),
          growth: 1,
        ),
      ]);
    }

    return out
        .map(
          (f) => FloraSnapshot(
            floraId: f.floraId,
            kind: f.kind,
            position: IslandPlacement.clampToIsland(
              f.position,
              inset: f.kind == FloraKind.tree ? 0.82 : 0.88,
            ),
            growth: f.growth,
            zone: f.zone,
            asset: f.asset,
            animation: f.animation,
            rotation: f.rotation,
          ),
        )
        .toList(growable: false);
  }

  int tierFromSummaryLevel(int level) =>
      IslandVisualConfig.prosperityTierFromLevel(level);
}
