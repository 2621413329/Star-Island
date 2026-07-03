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

  static const starterStoneAnchor = Offset(0.28, 0.64);

  static const _rightAnchors = {
    'record_shed': Offset(0.68, 0.56),
    'growth_house': Offset(0.74, 0.52),
    'growth_house_lv2': Offset(0.74, 0.52),
    'memory_mailbox': Offset(0.76, 0.60),
    'lighthouse': Offset(0.76, 0.56),
    'story_plaza': Offset(0.76, 0.58),
    'memory_fountain': Offset(0.62, 0.52),
    'growth_clocktower': Offset(0.72, 0.36),
    'habit_flowerbed': Offset(0.70, 0.68),
  };

  static const _leftAnchors = {
    'library_seed': Offset(0.18, 0.52),
    'emotion_windchime': Offset(0.34, 0.58),
    'quiet_tent': Offset(0.40, 0.64),
    'memory_gallery': Offset(0.20, 0.36),
    'companion_plaza': Offset(0.26, 0.64),
  };

  static const _upperAnchors = {
    'growth_academy': Offset(0.50, 0.26),
    'lighthouse_base': Offset(0.56, 0.36),
    'dream_observatory': Offset(0.68, 0.24),
  };

  static Offset preferredAnchor(
    BuildingConfig config, {
    required double islandRadius,
  }) {
    if (config.id == 'harbor_pier') {
      return IslandPlacement.harborPierAnchor(islandRadius: islandRadius);
    }
    if (config.id == 'starter_stone') {
      return starterStoneAnchor;
    }
    final raw = _rightAnchors[config.id] ??
        _leftAnchors[config.id] ??
        _upperAnchors[config.id] ??
        _randomIslandAnchor(config);
    final inset = _upperAnchors.containsKey(config.id) ? 0.78 : 0.86;
    if (IslandPlacement.isOnGrowthIsland(raw, inset: inset)) {
      return raw;
    }
    return IslandPlacement.clampToGrowthIsland(raw, inset: inset);
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
    if (_isZoneValidCandidate(
      config: config,
      anchor: resolved,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return resolved;
    }
    final zoneFallback = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
    );
    if (zoneFallback != null) return zoneFallback;
    if (_isZoneValidCandidate(
      config: config,
      anchor: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return MainIslandPlacementZones.clampBuildingAnchor(
        preferred,
        footprint,
      );
    }
    return zoneFallback ??
        MainIslandPlacementZones.clampBuildingAnchor(
          preferred,
          footprint,
        );
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

    for (var y = 0.34; y <= 0.72; y += 0.018) {
      for (var x = 0.18; x <= 0.82; x += 0.018) {
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

    for (var deg = 0; deg < 360; deg += 12) {
      final angle = deg * math.pi / 180;
      final candidate = IslandPlacement.pointOnGrowthIslandEdge(
        angle,
        islandRadiusScale: 0.72,
        inset: 0.72,
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

    final zoneOnly = _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
    );
    if (zoneOnly != null) return zoneOnly;

    if (_isZoneValidCandidate(
      config: config,
      anchor: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return MainIslandPlacementZones.clampBuildingAnchor(
        preferred,
        footprint,
      );
    }

    return MainIslandPlacementZones.clampBuildingAnchor(
      preferred,
      footprint,
    );
  }

  static Offset? findNearestZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    return _findZoneValidAnchor(
      config: config,
      preferred: preferred,
      footprint: footprint,
      academyAnchor: academyAnchor,
    );
  }

  static Offset? _findZoneValidAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    final bandTop = preferred.dy < 0.40 ? 0.12 : 0.34;
    final bandBottom = preferred.dy < 0.40 ? 0.36 : 0.72;
    Offset? best;
    var bestDistance = double.infinity;
    for (var y = bandTop; y <= bandBottom; y += 0.015) {
      for (var x = 0.18; x <= 0.82; x += 0.015) {
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
        final dist = (candidate - preferred).distanceSquared;
        if (dist < bestDistance) {
          bestDistance = dist;
          best = candidate;
        }
      }
    }
    return best;
  }

  static Offset _randomIslandAnchor(BuildingConfig config) {
    final rng = math.Random(_seed(config.id));
    for (var i = 0; i < 40; i++) {
      final candidate = Offset(
        0.34 + rng.nextDouble() * 0.32,
        0.47 + rng.nextDouble() * 0.16,
      );
      if (IslandPlacement.isOnIsland(candidate, inset: 0.86)) {
        return candidate;
      }
    }
    return IslandPlacement.clampToGrowthIsland(config.position, inset: 0.86);
  }

  static int placementPriority(BuildingConfig config) {
    return switch (config.id) {
      'starter_stone' => 1000,
      'growth_academy' => 960,
      'lighthouse' => 940,
      'growth_clocktower' => 935,
      'dream_observatory' => 928,
      'memory_fountain' => 925,
      'library_seed' => 930,
      'harbor_pier' => 900,
      'growth_house_lv2' || 'growth_house' => 880,
      'record_shed' || 'memory_mailbox' => 860,
      _
          when _rightAnchors.containsKey(config.id) ||
              _leftAnchors.containsKey(config.id) ||
              _upperAnchors.containsKey(config.id) =>
        820,
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

  static bool _overlapsAny(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed,
  ) {
    final rect = occupancyRect(anchor, footprint);
    for (final other in placed) {
      if (rect.overlaps(other.rect)) return true;
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
    return !_overlapsAny(anchor, footprint, placed);
  }

  static bool _isZoneValidCandidate({
    required BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    Offset? academyAnchor,
  }) {
    final rect = occupancyRect(anchor, footprint);
    return !MainIslandPlacementZones.overlapsForbiddenGroundForBuilding(
      rect,
      config.id,
      academyAnchor: academyAnchor,
      anchor: anchor,
      footprint: footprint,
    );
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
      : rect = IslandBuildingLayout.occupancyRect(anchor, footprint);

  final Offset anchor;
  final Offset footprint;
  final Rect rect;
}
