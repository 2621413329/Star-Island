import 'dart:ui';

import 'world_island_visual.dart';

/// 首页群岛：主岛居中，副岛落在开阔天空里，避开底图四角的花叶。
abstract final class WorldIslandLayout {
  static const mainSlotId = 'main';

  static const storyRankSlotIds = [
    'rank_0',
    'rank_1',
    'rank_2',
    'rank_3',
    'rank_4',
  ];

  static const slotIds = [
    mainSlotId,
    ...storyRankSlotIds,
  ];

  static const entries = <WorldIslandSlotLayout>[
    WorldIslandSlotLayout(
      slotId: 'rank_2',
      position: Offset(0.50, 0.16),
      depthScale: 0.82,
      zIndex: 8,
      rotationRadians: 0.02,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_0',
      position: Offset(0.22, 0.32),
      depthScale: 0.94,
      zIndex: 12,
      rotationRadians: -0.03,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_1',
      position: Offset(0.78, 0.30),
      depthScale: 0.90,
      zIndex: 13,
      rotationRadians: 0.03,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_3',
      position: Offset(0.28, 0.72),
      depthScale: 0.96,
      zIndex: 22,
      rotationRadians: -0.02,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_4',
      position: Offset(0.74, 0.70),
      depthScale: 0.88,
      zIndex: 21,
      rotationRadians: 0.025,
    ),
    WorldIslandSlotLayout(
      slotId: mainSlotId,
      position: Offset(0.50, 0.48),
      depthScale: WorldIslandVisualProfile.mainScale,
      zIndex: 30,
      rotationRadians: 0,
    ),
  ];

  static WorldIslandSlotLayout forSlot(String slotId) {
    for (final entry in entries) {
      if (entry.slotId == slotId) return entry;
    }
    return const WorldIslandSlotLayout(
      slotId: mainSlotId,
      position: Offset(0.50, 0.52),
      depthScale: WorldIslandVisualProfile.mainScale,
      zIndex: 30,
    );
  }

  static Offset positionFor(String slotId) => forSlot(slotId).position;

  static List<WorldIslandSlotLayout> sortedByDepth() {
    final copy = [...entries]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return copy;
  }
}

/// 首页群岛 Archipelago 布局：主岛居中，副岛环绕，远近/大小不对称。
class WorldIslandSlotLayout {
  const WorldIslandSlotLayout({
    required this.slotId,
    required this.position,
    required this.depthScale,
    required this.zIndex,
    this.rotationRadians = 0,
  });

  final String slotId;
  final Offset position;
  final double depthScale;
  final int zIndex;
  final double rotationRadians;

  double get opacity => 1.0;

  double get blurSigma => 0;

  double floatAmplitude({String? categoryId, bool isMain = false}) =>
      WorldIslandVisualProfile.floatAmplitude(
        isMain: isMain,
        categoryId: categoryId,
      );
}
