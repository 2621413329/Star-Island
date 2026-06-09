import 'dart:ui';

import 'island_terrain_config.dart';

/// Growth Island 2.0 固定三座建筑布局（位置不随 mood 变化）。
class IslandBuildingDef {
  const IslandBuildingDef({
    required this.id,
    required this.label,
    required this.anchor,
    required this.minProsperityTier,
    required this.layer,
  });

  final String id;
  final String label;
  final Offset anchor;
  final int minProsperityTier;
  final IslandTerrainLayer layer;

  double get depthScale => IslandTerrainConfig.layerScale(layer);
}

class IslandBuildingConfig {
  IslandBuildingConfig._();

  static const lighthouse = IslandBuildingDef(
    id: 'growth_lighthouse',
    label: '灯塔',
    anchor: Offset(0.76, 0.52),
    minProsperityTier: 2,
    layer: IslandTerrainLayer.mid,
  );

  static const library = IslandBuildingDef(
    id: 'growth_library',
    label: '图书馆',
    anchor: Offset(0.24, 0.48),
    minProsperityTier: 3,
    layer: IslandTerrainLayer.back,
  );

  static const memoryPlaza = IslandBuildingDef(
    id: 'growth_plaza',
    label: '记忆广场',
    anchor: Offset(0.50, 0.42),
    minProsperityTier: 4,
    layer: IslandTerrainLayer.front,
  );

  /// 后 → 前排序，保证绘制顺序正确。
  static const all = [library, lighthouse, memoryPlaza];

  static IslandBuildingDef? find(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }
}
