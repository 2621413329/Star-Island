import 'dart:math' as math;
import 'dart:ui';

import '../building/building_footprint.dart';
import '../config/growth_island_config_models.dart';
import 'island_placement.dart';
import 'main_island_placement_zones.dart';
import '../../world/engine/world_state.dart';

/// 成长岛建筑落点：关键建筑固定区域 + 其余稳定随机 + 防重叠。
class IslandBuildingLayout {
  const IslandBuildingLayout._();

  /// 左前岸，避开加宽后的小人禁区。
  static const starterStoneAnchor = Offset(0.20, 0.60);

  static const _fixedAnchorIds = {
    'starter_stone',
    'growth_academy',
    'harbor_pier',
  };

  static const _fixedSemanticAnchors = <String, Offset>{};

  /// 建筑间最小留白（归一化），用于 footprint 碰撞检测。
  static const overlapPadding = 0.055;

  static Offset preferredAnchor(
    BuildingConfig config, {
    required double islandRadius,
  }) {
    if (config.id == 'harbor_pier') {
      // 前缘正中河岸：贴岛缘略偏水域，避免落在草地中央。
      final edge = IslandPlacement.harborPierAnchor(islandRadius: islandRadius);
      return Offset(edge.dx, (edge.dy + 0.018).clamp(0.64, 0.72));
    }
    if (config.id == 'starter_stone') {
      return starterStoneAnchor;
    }
    if (usesFixedAnchor(config.id)) {
      return _fixedSemanticAnchors[config.id] ?? config.position;
    }
    final raw = _randomIslandAnchor(config);
    if (IslandPlacement.isOnGrowthIsland(raw, inset: 0.86)) {
      return raw;
    }
    return IslandPlacement.clampToGrowthIsland(raw, inset: 0.86);
  }

  static bool usesFixedAnchor(String buildingId) {
    return _fixedAnchorIds.contains(buildingId);
  }

  static bool isZoneValidForBuilding({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    return _isZoneValidCandidate(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    );
  }

  static Offset resolveAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    final resolved = _resolveAnchorCandidate(
      config: config,
      preferred: preferred,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (_isValidCandidate(
      config: config,
      anchor: resolved,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return resolved;
    }
    final zoneFallback = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
    if (zoneFallback != null) return zoneFallback;

    for (var y = 0.24; y <= 0.70; y += 0.012) {
      for (var x = 0.22; x <= 0.78; x += 0.012) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.86);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    return _findZoneValidAnchor(
          config: config,
          preferred: preferred,
          footprint: footprint,
          academyAnchor: academyAnchor,
          placed: placed,
        ) ??
        _safeFallbackAnchor(config);
  }

  static Offset _resolveAnchorCandidate({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (_isValidCandidate(
      config: config,
      anchor: preferred,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return preferred;
    }

    const attempts = <Offset>[
      Offset(0, 0),
      Offset(0.03, 0),
      Offset(-0.03, 0),
      Offset(0, 0.03),
      Offset(0, -0.03),
      Offset(0.04, 0.02),
      Offset(-0.04, 0.02),
      Offset(0.04, -0.02),
      Offset(-0.04, -0.02),
      Offset(0.06, 0),
      Offset(-0.06, 0),
      Offset(0, 0.06),
      Offset(0, -0.06),
    ];

    for (final delta in attempts) {
      final candidate = IslandPlacement.clampToGrowthIsland(
        preferred + delta,
        inset: 0.86,
      );
      if (_isValidCandidate(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    if (preferred.dy < 0.40) {
      final upperBand = _findZoneValidAnchor(
        config: config,
        preferred: preferred,
        footprint: footprint,
        academyAnchor: academyAnchor,
        placed: placed,
      );
      if (upperBand != null && !_overlapsAny(upperBand, footprint, placed)) {
        return upperBand;
      }
    }

    for (var ring = 1; ring <= 12; ring++) {
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final dist = 0.045 * ring;
        final candidate = IslandPlacement.clampToGrowthIsland(
          preferred + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          inset: 0.86,
        );
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var ring = 1; ring <= 36; ring++) {
      for (var i = 0; i < 24; i++) {
        final angle = i * math.pi / 12;
        final dist = 0.028 * ring;
        final candidate = IslandPlacement.clampToGrowthIsland(
          preferred + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          inset: 0.86,
        );
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var y = 0.36; y <= 0.70; y += 0.018) {
      for (var x = 0.22; x <= 0.78; x += 0.018) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.86);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    for (var y = 0.24; y <= 0.42; y += 0.014) {
      for (var x = 0.24; x <= 0.76; x += 0.014) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.82);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    final configFallback =
        IslandPlacement.clampToGrowthIsland(config.position, inset: 0.86);
    if (_isValidCandidate(
      config: config,
      anchor: configFallback,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return configFallback;
    }

    final zoneOnly = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
    if (zoneOnly != null) return zoneOnly;

    for (var y = 0.24; y <= 0.70; y += 0.010) {
      for (var x = 0.22; x <= 0.78; x += 0.010) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    return zoneOnly ?? _safeFallbackAnchor(config);
  }

  static Offset? findNearestZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
    List<PlacedFootprint> placed = const [],
  }) {
    return _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
      placed: placed,
    );
  }

  static Offset? _findZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
    List<PlacedFootprint> placed = const [],
  }) {
    final bandTop = preferred.dy < 0.40 ? 0.22 : 0.36;
    final bandBottom = preferred.dy < 0.40 ? 0.42 : 0.70;
    Offset? best;
    var bestDistance = double.infinity;
    for (var y = bandTop; y <= bandBottom; y += 0.015) {
      for (var x = 0.22; x <= 0.78; x += 0.015) {
        final candidate = Offset(x, y);
        if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.78)) {
          continue;
        }
        if (!_isZoneValidCandidate(
          config: config,
          anchor: candidate,
          footprint: footprint,
          academyAnchor: academyAnchor,
        )) {
          continue;
        }
        if (config.id != 'harbor_pier' &&
            !BuildingFootprint.isFullyOnGrowthIsland(candidate, footprint)) {
          continue;
        }
        if (_overlapsAny(candidate, footprint, placed)) {
          continue;
        }
        final dist = (candidate - preferred).distanceSquared;
        if (dist < bestDistance) {
          bestDistance = dist;
          best = candidate;
        }
      }
    }
    return best;
  }

  static bool _isFrontHalfBuilding(BuildingConfig config) {
    return switch (config.type) {
      'house' ||
      'shed' ||
      'tent' ||
      'fountain' ||
      'flowerbed' ||
      'windchime' ||
      'mailbox' ||
      'library' ||
      'gallery' =>
        true,
      _ => config.id == 'memory_mailbox' ||
          config.id == 'record_shed' ||
          config.id == 'quiet_tent' ||
          config.id == 'memory_fountain' ||
          config.id == 'habit_flowerbed' ||
          config.id == 'emotion_windchime' ||
          config.id == 'library_seed' ||
          config.id == 'memory_gallery' ||
          config.id == 'growth_house' ||
          config.id == 'growth_house_lv2',
    };
  }

  static Offset _randomIslandAnchor(BuildingConfig config) {
    final rng = math.Random(_seed(config.id));
    final upperLandmark = config.type == 'observatory' ||
        config.type == 'clocktower' ||
        config.id == 'lighthouse';
    final frontHalf = _isFrontHalfBuilding(config);
    for (var i = 0; i < 96; i++) {
      final dx = switch (config.id) {
        'dream_observatory' => 0.56 + rng.nextDouble() * 0.10,
        'lighthouse' => 0.62 + rng.nextDouble() * 0.14,
        'growth_clocktower' => 0.52 + rng.nextDouble() * 0.18,
        // 前半侧建筑分列左右，避开小人中央带。
        _ when frontHalf => rng.nextBool()
            ? 0.18 + rng.nextDouble() * 0.16
            : 0.66 + rng.nextDouble() * 0.16,
        _ => 0.24 + rng.nextDouble() * 0.52,
      };
      final dy = switch (config.id) {
        'dream_observatory' || 'growth_clocktower' => 0.34 + rng.nextDouble() * 0.08,
        'lighthouse' => 0.32 + rng.nextDouble() * 0.08,
        _ when upperLandmark => 0.32 + rng.nextDouble() * 0.10,
        // 小/中建筑落在岛面前半侧，但避开左右广场带（约 y≥0.56）。
        _ when frontHalf => 0.50 + rng.nextDouble() * 0.06,
        _ => 0.38 + rng.nextDouble() * 0.20,
      };
      final candidate = Offset(dx, dy);
      if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.86)) {
        continue;
      }
      if (MainIslandPlacementZones.protagonistExclusion.contains(candidate)) {
        continue;
      }
      return candidate;
    }
    return _safeFallbackAnchor(config);
  }

  static Offset safeFallbackAnchor(BuildingConfig config) {
    return _safeFallbackAnchor(config);
  }

  static Offset _safeFallbackAnchor(BuildingConfig config) {
    final anchor = switch (config.id) {
      'dream_observatory' => const Offset(0.56, 0.36),
      'lighthouse' => const Offset(0.76, 0.34),
      'growth_clocktower' => const Offset(0.58, 0.34),
      'memory_gallery' => const Offset(0.78, 0.52),
      'library_seed' => const Offset(0.22, 0.52),
      'growth_house' || 'growth_house_lv2' => const Offset(0.20, 0.50),
      'emotion_windchime' => const Offset(0.22, 0.50),
      'quiet_tent' => const Offset(0.78, 0.52),
      'record_shed' => const Offset(0.80, 0.50),
      'habit_flowerbed' => const Offset(0.78, 0.50),
      'memory_fountain' => const Offset(0.20, 0.52),
      'memory_mailbox' => const Offset(0.80, 0.52),
      _ => _nudgedConfigPosition(config),
    };
    if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
      return anchor;
    }
    return MainIslandPlacementZones.clampBuildingAnchor(
      anchor,
      const Offset(0.20, 0.18),
    );
  }

  static Offset _nudgedConfigPosition(BuildingConfig config) {
    var pos = config.position;
    final frontHalf = _isFrontHalfBuilding(config);
    if (MainIslandPlacementZones.protagonistExclusion.contains(pos) ||
        (pos.dx - 0.5).abs() < 0.10) {
      pos = Offset(
        pos.dx < 0.5 ? 0.24 : 0.76,
        frontHalf ? 0.58 : (pos.dy > 0.48 ? 0.40 : pos.dy),
      );
    } else if (frontHalf && pos.dy < 0.52) {
      // 小/中建筑不要被挤回后景导致“消失感”。
      pos = Offset(pos.dx, 0.58);
    }
    final nudged = Offset(
      (pos.dx - 0.5).abs() < 0.10 ? (pos.dx < 0.5 ? 0.24 : 0.76) : pos.dx,
      pos.dy,
    );
    return MainIslandPlacementZones.clampBuildingAnchor(
      nudged,
      const Offset(0.20, 0.18),
    );
  }

  static int placementPriority(BuildingConfig config) {
    return switch (config.id) {
      'starter_stone' => 1000,
      'growth_academy' => 960,
      'harbor_pier' => 900,
      _ => 100 + (config.size.dx * config.size.dy * 400).round(),
    };
  }

  static bool overlapsBuilding(
    Offset point,
    BuildingSnapshot building, {
    double margin = 0,
  }) {
    return occupancyRect(building.anchor, building.size, margin: margin)
        .contains(point);
  }

  static bool overlapsAnyBuilding(
    Offset point,
    Iterable<BuildingSnapshot> buildings, {
    double margin = 0,
  }) {
    for (final building in buildings) {
      if (overlapsBuilding(point, building, margin: margin)) {
        return true;
      }
    }
    return false;
  }

  static bool collisionOverlapsPlaced(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed,
  ) {
    return _overlapsAny(anchor, footprint, placed);
  }

  static bool _overlapsAny(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed,
  ) {
    final rect = collisionRect(anchor, footprint).inflate(overlapPadding * 0.5);
    for (final other in placed) {
      if (rect.overlaps(other.collisionRect.inflate(overlapPadding * 0.5))) {
        return true;
      }
    }
    return false;
  }

  static bool _isValidCandidate({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (config.id != 'harbor_pier' &&
        !BuildingFootprint.isFullyOnGrowthIsland(anchor, footprint)) {
      return false;
    }
    if (!_isZoneValidCandidate(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (_overlapsProtagonistZone(config, anchor, footprint)) {
      return false;
    }
    return !_overlapsAny(anchor, footprint, placed);
  }

  static bool _overlapsProtagonistZone(
    BuildingConfig config,
    Offset anchor,
    Offset footprint,
  ) {
    if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
      return false;
    }
    // 只用脚点附近占地判断，避免高大建筑上半身视觉框误伤左右岸合法落点。
    return footPadRect(anchor, footprint)
        .overlaps(MainIslandPlacementZones.protagonistExclusion);
  }

  /// 建筑贴地脚垫：用于小人禁区判定。
  static Rect footPadRect(Offset anchor, Offset footprint) {
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy + footprint.dy * 0.02),
      width: footprint.dx * 0.58,
      height: math.max(0.05, footprint.dy * 0.30),
    );
  }

  static bool _isZoneValidCandidate({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    if (_violatesLandmarkBand(config, anchor)) {
      return false;
    }
    if (config.type == 'observatory' &&
        academyAnchor != null &&
        (anchor - academyAnchor).distance < 0.082) {
      return false;
    }
    final rect = occupancyRect(anchor, footprint);
    return !MainIslandPlacementZones.overlapsForbiddenGroundForBuilding(
      rect,
      config.id,
      academyAnchor: academyAnchor,
      anchor: anchor,
      footprint: footprint,
    );
  }

  /// 高塔/天文台等后景地标应落在上半岛，避免挤入主角区或广场带。
  static bool _violatesLandmarkBand(BuildingConfig config, Offset anchor) {
    final upperLandmark = config.type == 'observatory' ||
        config.type == 'clocktower' ||
        config.type == 'lighthouse' ||
        config.type == 'lighthouse_base';
    if (!upperLandmark) return false;
    if (anchor.dy > 0.46) return true;
    if (config.type == 'observatory' && anchor.dx > 0.64) return true;
    return false;
  }

  static Rect occupancyRect(
    Offset anchor,
    Offset footprint, {
    double margin = 0,
  }) {
    final w = footprint.dx * 0.90 + margin;
    final h = footprint.dy * 0.68 + margin;
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - footprint.dy * 0.34),
      width: w,
      height: h,
    );
  }

  /// 建筑间碰撞盒：比占地略大，避免视觉重叠。
  static Rect collisionRect(
    Offset anchor,
    Offset footprint, {
    double margin = 0,
  }) {
    final w = footprint.dx * 0.98 + margin;
    final h = footprint.dy * 0.84 + margin;
    return Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - footprint.dy * 0.40),
      width: w,
      height: h,
    );
  }

  /// 建筑脚点禁草区：避免小草/草裙画在建筑底部。
  static Rect buildingFootGrassExclusion(BuildingSnapshot building) {
    final footprint = building.size;
    return Rect.fromCenter(
      center: Offset(
        building.anchor.dx,
        building.anchor.dy + footprint.dy * 0.06,
      ),
      width: footprint.dx * 1.22,
      height: footprint.dy * 0.42,
    );
  }

  static List<Rect> buildingFootGrassExclusions(
    Iterable<BuildingSnapshot> buildings,
  ) {
    return [
      for (final building in buildings)
        buildingFootGrassExclusion(building).inflate(0.012),
    ];
  }

  static int _seed(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = 0x1fffffff & (h + c);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= (h >> 11);
    return 0x1fffffff & (h + ((0x00003fff & h) << 15));
  }
}

class PlacedFootprint {
  PlacedFootprint({required this.anchor, required this.footprint})
      : rect = IslandBuildingLayout.occupancyRect(anchor, footprint),
        collisionRect =
            IslandBuildingLayout.collisionRect(anchor, footprint);

  final Offset anchor;
  final Offset footprint;
  final Rect rect;
  final Rect collisionRect;
}
