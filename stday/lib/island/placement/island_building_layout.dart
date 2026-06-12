import 'dart:math' as math;
import 'dart:ui';

import '../config/growth_island_config_models.dart';
import 'island_placement.dart';
import '../../world/engine/world_state.dart';

/// 成长岛建筑落点：关键建筑固定区域 + 其余稳定随机 + 防重叠。
class IslandBuildingLayout {
  const IslandBuildingLayout._();

  static const starterStoneAnchor = Offset(0.28, 0.64);

  static const _rightAnchors = {
    'record_shed': Offset(0.66, 0.54),
    'growth_house': Offset(0.62, 0.50),
    'growth_house_lv2': Offset(0.62, 0.50),
    'memory_mailbox': Offset(0.72, 0.58),
    'lighthouse': Offset(0.76, 0.46),
  };

  static const _leftAnchors = {
    'library_seed': Offset(0.28, 0.48),
  };

  static const _upperAnchors = {
    'growth_academy': Offset(0.50, 0.40),
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
    return _rightAnchors[config.id] ??
        _leftAnchors[config.id] ??
        _upperAnchors[config.id] ??
        _randomIslandAnchor(config);
  }

  static Offset resolveAnchor({
    required BuildingConfig config,
    required Offset preferred,
    required Offset footprint,
    required List<PlacedFootprint> placed,
  }) {
    if (!_overlapsAny(preferred, footprint, placed)) {
      return IslandPlacement.clampToIsland(preferred, inset: 0.86);
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
      final candidate = IslandPlacement.clampToIsland(
        preferred + delta,
        inset: 0.86,
      );
      if (!_overlapsAny(candidate, footprint, placed)) {
        return candidate;
      }
    }

    for (var ring = 1; ring <= 5; ring++) {
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final dist = 0.045 * ring;
        final candidate = IslandPlacement.clampToIsland(
          preferred + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
          inset: 0.86,
        );
        if (!_overlapsAny(candidate, footprint, placed)) {
          return candidate;
        }
      }
    }

    return IslandPlacement.clampToIsland(preferred, inset: 0.86);
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
    return IslandPlacement.clampToIsland(config.position, inset: 0.86);
  }

  static int placementPriority(BuildingConfig config) {
    return switch (config.id) {
      'starter_stone' => 1000,
      'growth_academy' => 960,
      'lighthouse' => 940,
      'library_seed' => 930,
      'harbor_pier' => 900,
      'growth_house_lv2' || 'growth_house' => 880,
      'record_shed' || 'memory_mailbox' => 860,
      _ when _rightAnchors.containsKey(config.id) ||
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
