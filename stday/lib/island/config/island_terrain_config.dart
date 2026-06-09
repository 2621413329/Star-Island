import 'dart:ui';

/// 成长岛地形分层：后景 / 中景 / 前景（用于建筑与平台纵深）。
enum IslandTerrainLayer { back, mid, front }

/// 2D 阶梯台地定义（归一化坐标）。
class GrowthTerraceDef {
  const GrowthTerraceDef({
    required this.center,
    required this.width,
    required this.height,
    required this.lift,
    required this.layer,
    required this.minTier,
  });

  final Offset center;
  final double width;
  final double height;
  /// 相对抬升（归一化高度）。
  final double lift;
  final IslandTerrainLayer layer;
  final int minTier;
}

/// 岛缘浮空小平台。
class GrowthFloatingPadDef {
  const GrowthFloatingPadDef({
    required this.anchor,
    required this.size,
    required this.drop,
    required this.minTier,
  });

  final Offset anchor;
  final double size;
  /// 相对主岛向下的偏移（归一化）。
  final double drop;
  final int minTier;
}

class IslandTerrainConfig {
  IslandTerrainConfig._();

  static const terraces = [
    GrowthTerraceDef(
      center: Offset(0.32, 0.54),
      width: 0.22,
      height: 0.10,
      lift: 0.012,
      layer: IslandTerrainLayer.back,
      minTier: 2,
    ),
    GrowthTerraceDef(
      center: Offset(0.68, 0.54),
      width: 0.20,
      height: 0.09,
      lift: 0.010,
      layer: IslandTerrainLayer.mid,
      minTier: 2,
    ),
    GrowthTerraceDef(
      center: Offset(0.50, 0.46),
      width: 0.18,
      height: 0.08,
      lift: 0.018,
      layer: IslandTerrainLayer.front,
      minTier: 3,
    ),
  ];

  static const floatingPads = [
    GrowthFloatingPadDef(
      anchor: Offset(0.18, 0.58),
      size: 0.06,
      drop: 0.04,
      minTier: 3,
    ),
    GrowthFloatingPadDef(
      anchor: Offset(0.82, 0.57),
      size: 0.055,
      drop: 0.035,
      minTier: 3,
    ),
    GrowthFloatingPadDef(
      anchor: Offset(0.50, 0.62),
      size: 0.07,
      drop: 0.05,
      minTier: 4,
    ),
  ];

  static List<GrowthTerraceDef> terracesForTier(int tier) =>
      terraces.where((t) => tier >= t.minTier).toList();

  static List<GrowthFloatingPadDef> padsForTier(int tier) =>
      floatingPads.where((p) => tier >= p.minTier).toList();

  /// 透视缩放：后景小、前景大。
  static double layerScale(IslandTerrainLayer layer) => switch (layer) {
        IslandTerrainLayer.back => 0.90,
        IslandTerrainLayer.mid => 0.96,
        IslandTerrainLayer.front => 1.06,
      };
}
