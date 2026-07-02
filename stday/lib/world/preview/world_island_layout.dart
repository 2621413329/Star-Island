import 'dart:ui';

import 'world_island_visual.dart';

/// 首页群岛布局：副岛环绕主岛，间距足够避免遮挡。
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
      slotId: 'rank_0',
      position: Offset(0.20, 0.26),
      depthScale: 0.94,
      zIndex: 10,
      rotationRadians: -0.07,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_1',
      position: Offset(0.80, 0.24),
      depthScale: 0.94,
      zIndex: 11,
      rotationRadians: 0.08,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_2',
      position: Offset(0.50, 0.14),
      depthScale: 0.88,
      zIndex: 8,
      rotationRadians: 0.04,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_3',
      position: Offset(0.18, 0.74),
      depthScale: 0.92,
      zIndex: 20,
      rotationRadians: -0.06,
    ),
    WorldIslandSlotLayout(
      slotId: 'rank_4',
      position: Offset(0.82, 0.72),
      depthScale: 0.90,
      zIndex: 19,
      rotationRadians: 0.065,
    ),
    WorldIslandSlotLayout(
      slotId: mainSlotId,
      position: Offset(0.50, 0.56),
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
      position: Offset(0.50, 0.56),
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
