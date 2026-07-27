import 'dart:ui';

import '../../world/island/island_placement.dart';
import '../building/building_footprint.dart';
import 'large_tree_shore_parcels.dart';

/// 主岛程序化放置专用区域约束（不影响副岛 [StoryIslandWorldBuilder]）。
class MainIslandPlacementZones {
  MainIslandPlacementZones._();

  /// 与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = Offset(0.5, 0.625);

  /// 主角硬禁区：建筑 / 大树 / 池塘等不可进入（收窄以恢复装饰可见空间）。
  static Rect get protagonistExclusion => Rect.fromCenter(
        center: Offset(protagonistFoot.dx, protagonistFoot.dy + 0.01),
        width: 0.22,
        height: 0.13,
      );

  /// 主角软禁区：小草/小花不可贴脚，但允许落在左右岸。
  static Rect get protagonistSoftExclusion => Rect.fromCenter(
        center: protagonistFoot,
        width: 0.22,
        height: 0.12,
      );

  /// 岛心主视觉留白（收窄，避免把中前岸整片空掉）。
  static Rect get centralVoid => Rect.fromCenter(
        center: const Offset(0.5, 0.50),
        width: 0.10,
        height: 0.06,
      );

  /// 成长学院后方整带禁放：学院上方不允许任何建筑或装饰。
  static Rect academyRearExclusion(
      {Offset academyAnchor = academyDefaultAnchor}) {
    final bottom = (academyAnchor.dy - 0.01).clamp(0.08, 0.55);
    return Rect.fromLTRB(0.06, 0.0, 0.94, bottom);
  }

  static const academyDefaultAnchor = Offset(0.50, 0.44);

  /// 广场本体由建筑 footprint 避让；不再额外硬禁前侧左右岸（否则前岸空着）。
  static List<Rect> get plazaExclusions => const [];

  /// 7 棵大树岸线独占区（建筑 / 草花不可占）。
  static List<Rect> get largeTreeShoreParcels => LargeTreeShoreParcels.all;

  static bool overlapsLargeTreeShoreParcel(Rect occupancy) =>
      LargeTreeShoreParcels.overlapsAnyParcel(occupancy);

  /// 建筑 footprint 略大于 parcel 边界时也视为占用（宽体建筑需额外留白）。
  static bool buildingOverlapsLargeTreeShoreParcel(Rect occupancy) {
    for (final parcel in largeTreeShoreParcels) {
      if (meaningfullyOverlaps(occupancy.inflate(0.016), parcel)) {
        return true;
      }
    }
    return false;
  }

  static bool meaningfullyOverlaps(Rect a, Rect b) =>
      _meaningfullyOverlaps(a, b);

  static bool _meaningfullyOverlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final hit = a.intersect(b);
    return hit.width > 0.002 && hit.height > 0.002;
  }

  static bool overlapsForbiddenGround(
    Rect occupancy, {
    Offset? academyAnchor,
    Iterable<Rect> extra = const [],
  }) {
    if (occupancy.overlaps(protagonistExclusion)) return true;
    if (_meaningfullyOverlaps(occupancy, centralVoid)) return true;
    if (_meaningfullyOverlaps(
      occupancy,
      academyRearExclusion(
        academyAnchor: academyAnchor ?? academyDefaultAnchor,
      ),
    )) {
      return true;
    }
    for (final plaza in plazaExclusions) {
      if (_meaningfullyOverlaps(occupancy, plaza)) return true;
    }
    for (final block in extra) {
      if (_meaningfullyOverlaps(occupancy, block)) return true;
    }
    return false;
  }

  /// 主岛建筑专用禁放检测（广场本体、栈桥、学院自身豁免）。
  static bool overlapsForbiddenGroundForBuilding(
    Rect occupancy,
    String buildingId, {
    Offset? academyAnchor,
    Offset? anchor,
    Offset? footprint,
  }) {
    if (buildingId != 'harbor_pier' && buildingId != 'starter_stone') {
      final foot = (anchor != null && footprint != null)
          ? Rect.fromCenter(
              center: Offset(
                anchor.dx,
                anchor.dy + footprint.dy * 0.02,
              ),
              width: footprint.dx * 0.58,
              height: footprint.dy < 0.08 ? 0.05 : footprint.dy * 0.30,
            )
          : occupancy;
      if (foot.overlaps(protagonistExclusion)) return true;
    }
    // 高塔立面上半可探入岛心留白；只禁普通建筑占中心。
    const slenderLandmarks = {
      'dream_observatory',
      'growth_clocktower',
      'lighthouse',
      'lighthouse_base',
    };
    if (buildingId != 'growth_academy' &&
        buildingId != 'starter_stone' &&
        buildingId != 'harbor_pier' &&
        !slenderLandmarks.contains(buildingId) &&
        _meaningfullyOverlaps(occupancy, centralVoid)) {
      return true;
    }
    // 学院后方整带禁建：以锚点为准（高大建筑上半身可伸入后景天空）。
    if (buildingId != 'growth_academy' &&
        anchor != null &&
        academyAnchor != null &&
        anchor.dy < academyAnchor.dy - 0.01) {
      return true;
    }
    if (buildingId != 'growth_academy' &&
        anchor == null &&
        _meaningfullyOverlaps(
          occupancy,
          academyRearExclusion(
            academyAnchor: academyAnchor ?? academyDefaultAnchor,
          ),
        )) {
      return true;
    }
    for (final plaza in plazaExclusions) {
      if (buildingId == 'starter_stone' &&
          _isCompanionPlazaRect(plaza)) {
        continue;
      }
      if (buildingId == 'harbor_pier') continue;
      if (buildingId == 'story_plaza' && _isStoryPlazaRect(plaza)) continue;
      if (buildingId == 'companion_plaza' && _isCompanionPlazaRect(plaza)) {
        continue;
      }
      if (_meaningfullyOverlaps(occupancy, plaza)) return true;
    }
    if (buildingId != 'starter_stone' &&
        buildingId != 'harbor_pier' &&
        buildingOverlapsLargeTreeShoreParcel(occupancy)) {
      return true;
    }
    return false;
  }

  static bool _isStoryPlazaRect(Rect plaza) =>
      (plaza.center.dx - 0.76).abs() < 0.02;

  static bool _isCompanionPlazaRect(Rect plaza) =>
      (plaza.center.dx - 0.26).abs() < 0.02;

  /// 建筑边缘安全距：锚点需在岛缘内，且 footprint 半宽不越界。
  static Offset clampBuildingAnchor(
    Offset anchor,
    Offset footprint, {
    double islandInset = 0.82,
    double islandRadius = 1.0,
  }) {
    var clamped =
        IslandPlacement.clampToGrowthIsland(
          anchor,
          inset: islandInset,
          islandRadius: islandRadius,
        );
    if (BuildingFootprint.isFullyOnGrowthIsland(
      clamped,
      footprint,
      inset: islandInset,
      islandRadius: islandRadius,
    )) {
      return clamped;
    }

    final edge = BuildingFootprint.edgeBoundsRect(clamped, footprint);
    final halfW = edge.width / 2;
    for (var attempt = 0; attempt < 24; attempt++) {
      final nudge = Offset(
        (attempt.isOdd ? -1 : 1) * 0.012 * ((attempt ~/ 2) + 1),
        0.008 * ((attempt ~/ 4) + 1),
      );
      final candidate = IslandPlacement.clampToGrowthIsland(
        clamped + nudge,
        inset: islandInset,
        islandRadius: islandRadius,
      );
      if (BuildingFootprint.isFullyOnGrowthIsland(
        candidate,
        footprint,
        inset: islandInset,
        islandRadius: islandRadius,
      )) {
        return candidate;
      }
    }

    if (!IslandPlacement.isOnGrowthIsland(
      Offset(clamped.dx - halfW, clamped.dy),
      inset: islandInset,
      islandRadius: islandRadius,
    )) {
      clamped = IslandPlacement.clampToGrowthIsland(
        clamped,
        inset: islandInset - 0.04,
        islandRadius: islandRadius,
      );
    }
    return clamped;
  }
}
