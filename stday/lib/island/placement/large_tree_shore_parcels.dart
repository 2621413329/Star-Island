import 'dart:ui';

import '../../world/island/island_placement.dart';

/// 主岛 7 棵大树岸线独占 parcel（建筑 / 草花 / 其它地面装饰不可占用）。
///
/// 槽位在满半径下错开定义，再按 [IslandState.radius] 相对岛心缩放，
/// 避免 clamp 到扁椭圆岸缘后挤成一坨。
class LargeTreeShoreParcels {
  LargeTreeShoreParcels._();

  /// 满半径（1.0）锚点：必须在 inset=0.84 扁椭圆内。
  /// 邻居需满足缩放至 0.82 后脚垫仍不重叠（|dx|≳0.14 或 |dy|≳0.09）。
  static const slotsAtFullRadius = <String, Offset>{
    'tree_large_01': Offset(0.13, 0.57),
    'tree_large_01b': Offset(0.27, 0.46),
    'tree_large_01c': Offset(0.30, 0.62),
    'life_tree_01': Offset(0.40, 0.46),
    'tree_large_02': Offset(0.87, 0.57),
    'tree_large_02b': Offset(0.73, 0.46),
    'tree_large_02c': Offset(0.70, 0.62),
  };

  /// 近似极角（扇区搜索用）。
  static const shoreAngleByTreeId = <String, double>{
    'tree_large_01': 2.95,
    'tree_large_01b': 3.55,
    'tree_large_01c': 1.95,
    'life_tree_01': 3.70,
    'tree_large_02': 0.20,
    'tree_large_02b': -0.40,
    'tree_large_02c': 1.20,
  };

  static const shorePolarByTreeId = <String, (double angle, double radial)>{
    'tree_large_01': (2.95, 0.90),
    'tree_large_01b': (3.55, 0.70),
    'tree_large_01c': (1.95, 0.94),
    'life_tree_01': (3.70, 0.50),
    'tree_large_02': (0.20, 0.90),
    'tree_large_02b': (-0.40, 0.70),
    'tree_large_02c': (1.20, 0.94),
  };

  static const _parcelLayoutRadius = 0.82;
  static const _parcelWidth = 0.09;
  static const _parcelHeight = 0.11;
  static const _centerLift = 0.02;

  static Map<String, Offset> get preferredSlotByTreeId => {
        for (final id in slotsAtFullRadius.keys)
          id: shoreSlot(id, islandRadius: _parcelLayoutRadius),
      };

  /// 按当前岛屿半径缩放独占槽位（相对岛心）。
  static Offset shoreSlot(
    String treeId, {
    required double islandRadius,
  }) {
    final full = slotsAtFullRadius[treeId];
    if (full == null) return IslandPlacement.center;
    final scale = IslandPlacement.effectiveIslandRadius(islandRadius);
    return Offset(
      IslandPlacement.center.dx +
          (full.dx - IslandPlacement.center.dx) * scale,
      IslandPlacement.center.dy +
          (full.dy - IslandPlacement.center.dy) * scale,
    );
  }

  static List<Rect> get all => [
        for (final id in slotsAtFullRadius.keys)
          parcelForTreeId(id) ?? Rect.zero,
      ];

  static Rect parcelAt(Offset anchor) => Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy - _centerLift),
        width: _parcelWidth,
        height: _parcelHeight,
      );

  static Rect? parcelForTreeId(String treeId) {
    if (!slotsAtFullRadius.containsKey(treeId)) return null;
    return parcelAt(shoreSlot(treeId, islandRadius: _parcelLayoutRadius));
  }

  static bool overlapsAnyParcel(
    Rect occupancy, {
    String? exemptTreeId,
  }) {
    for (final id in slotsAtFullRadius.keys) {
      if (exemptTreeId != null && id == exemptTreeId) continue;
      final parcel = parcelForTreeId(id);
      if (parcel == null) continue;
      if (_meaningfullyOverlaps(occupancy, parcel)) return true;
    }
    return false;
  }

  static bool _meaningfullyOverlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final hit = a.intersect(b);
    return hit.width > 0.002 && hit.height > 0.002;
  }
}
