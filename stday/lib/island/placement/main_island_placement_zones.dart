import 'dart:ui';

import '../../world/island/island_placement.dart';
import '../building/building_footprint.dart';

/// 主岛程序化放置专用区域约束（不影响副岛 [StoryIslandWorldBuilder]）。
class MainIslandPlacementZones {
  MainIslandPlacementZones._();

  /// 与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = Offset(0.5, 0.625);

  /// 主角占位：建筑与装饰均不可进入。
  static Rect get protagonistExclusion => Rect.fromCenter(
        center: Offset(protagonistFoot.dx, protagonistFoot.dy - 0.055),
        width: 0.26,
        height: 0.24,
      );

  /// 岛心主视觉留白（约占岛面 15–18%）。
  static Rect get centralVoid => Rect.fromCenter(
        center: const Offset(0.5, 0.52),
        width: 0.22,
        height: 0.16,
      );

  /// 成长学院正后方禁放区（窄楔形，不占用全岛后缘）。
  static Rect academyRearExclusion({Offset academyAnchor = academyDefaultAnchor}) {
    final bottom = (academyAnchor.dy - 0.04).clamp(0.10, 0.30);
    final height = bottom - 0.06;
    return Rect.fromCenter(
      center: Offset(
        academyAnchor.dx,
        0.06 + height / 2,
      ),
      width: 0.30,
      height: height,
    );
  }

  static const academyDefaultAnchor = Offset(0.50, 0.26);

  /// 广场禁放（故事广场 / 陪伴广场 footprint 近似区）。
  static List<Rect> get plazaExclusions => [
        Rect.fromCenter(
          center: const Offset(0.76, 0.58),
          width: 0.22,
          height: 0.14,
        ),
        Rect.fromCenter(
          center: const Offset(0.26, 0.64),
          width: 0.22,
          height: 0.14,
        ),
      ];

  static bool meaningfullyOverlaps(Rect a, Rect b) => _meaningfullyOverlaps(a, b);

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
    if (buildingId != 'harbor_pier' &&
        occupancy.overlaps(protagonistExclusion)) {
      return true;
    }
    if (buildingId != 'growth_academy' &&
        buildingId != 'harbor_pier' &&
        _meaningfullyOverlaps(occupancy, centralVoid)) {
      return true;
    }
    if (buildingId != 'growth_academy' &&
        anchor != null &&
        academyAnchor != null &&
        (anchor.dx - academyAnchor.dx).abs() < 0.16 &&
        anchor.dy < academyAnchor.dy - 0.03) {
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
      if (buildingId == 'story_plaza' && _isStoryPlazaRect(plaza)) continue;
      if (buildingId == 'companion_plaza' && _isCompanionPlazaRect(plaza)) {
        continue;
      }
      if (_meaningfullyOverlaps(occupancy, plaza)) return true;
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
    double islandInset = 0.86,
  }) {
    var clamped = IslandPlacement.clampToGrowthIsland(anchor, inset: islandInset);
    if (BuildingFootprint.isFullyOnGrowthIsland(
      clamped,
      footprint,
      inset: islandInset,
    )) {
      return clamped;
    }

    final edge = BuildingFootprint.edgeBoundsRect(clamped, footprint);
    final halfW = edge.width / 2;
    for (var attempt = 0; attempt < 24; attempt++) {
      final nudge = Offset(
        (attempt.isOdd ? -1 : 1) * 0.012 * ((attempt ~/ 2) + 1),
        0,
      );
      final candidate = IslandPlacement.clampToGrowthIsland(
        clamped + nudge,
        inset: islandInset,
      );
      if (BuildingFootprint.isFullyOnGrowthIsland(
        candidate,
        footprint,
        inset: islandInset,
      )) {
        return candidate;
      }
    }

    if (!IslandPlacement.isOnGrowthIsland(
      Offset(clamped.dx - halfW, clamped.dy),
      inset: islandInset,
    )) {
      clamped = IslandPlacement.clampToGrowthIsland(clamped, inset: islandInset - 0.04);
    }
    return clamped;
  }
}
