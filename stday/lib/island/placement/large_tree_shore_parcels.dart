import 'dart:ui';

/// 主岛 7 棵大树岸线独占 parcel（建筑 / 草花 / 其它地面装饰不可占用）。
class LargeTreeShoreParcels {
  LargeTreeShoreParcels._();

  /// 与 [DecorPlacementResolver] 大树优先缘位对齐。
  static const preferredSlotByTreeId = <String, Offset>{
    'tree_large_01': Offset(0.12, 0.44),
    'tree_large_01b': Offset(0.14, 0.54),
    'tree_large_01c': Offset(0.24, 0.68),
    'tree_large_02': Offset(0.86, 0.46),
    'tree_large_02b': Offset(0.86, 0.58),
    'tree_large_02c': Offset(0.76, 0.68),
    'life_tree_01': Offset(0.40, 0.50),
  };

  static const _parcelWidth = 0.105;
  static const _parcelHeight = 0.125;
  static const _centerLift = 0.02;

  static List<Rect> get all => [
        for (final slot in preferredSlotByTreeId.values) parcelAt(slot),
      ];

  static Rect parcelAt(Offset anchor) => Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy - _centerLift),
        width: _parcelWidth,
        height: _parcelHeight,
      );

  static Rect? parcelForTreeId(String treeId) {
    final slot = preferredSlotByTreeId[treeId];
    if (slot == null) return null;
    return parcelAt(slot);
  }

  /// 占用区是否与任一 parcel 有意义重叠（大树自身 parcel 可豁免）。
  static bool overlapsAnyParcel(
    Rect occupancy, {
    String? exemptTreeId,
  }) {
    for (final entry in preferredSlotByTreeId.entries) {
      if (exemptTreeId != null && entry.key == exemptTreeId) continue;
      if (_meaningfullyOverlaps(occupancy, parcelAt(entry.value))) {
        return true;
      }
    }
    return false;
  }

  static bool _meaningfullyOverlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final hit = a.intersect(b);
    return hit.width > 0.002 && hit.height > 0.002;
  }
}
