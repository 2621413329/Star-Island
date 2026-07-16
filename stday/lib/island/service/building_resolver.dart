import 'dart:ui';

import '../../world/engine/world_state.dart';
import '../config/building_config.dart';
import '../config/growth_island_config_models.dart' as growth;
import '../building/building_footprint.dart';
import '../placement/island_building_layout.dart';
import '../placement/island_placement.dart';
import '../placement/main_island_placement_zones.dart';
import '../building/plaza_terrace_renderer.dart';
import 'building_display_names.dart';

/// 根据繁荣度解锁固定三座成长建筑。
class BuildingResolver {
  const BuildingResolver();

  List<BuildingSnapshot> resolve({required int prosperityTier}) {
    final out = <BuildingSnapshot>[];
    for (final def in IslandBuildingConfig.all) {
      if (prosperityTier >= def.minProsperityTier) {
        out.add(BuildingSnapshot(
          definitionId: def.id,
          level: (prosperityTier - def.minProsperityTier + 1).clamp(1, 3),
          anchor: def.anchor,
        ));
      }
    }
    return out;
  }

  List<BuildingSnapshot> resolveConfigured({
    required List<growth.BuildingConfig> configs,
    required double islandRadius,
  }) {
    final latestByType = <String, growth.BuildingConfig>{};
    for (final config in configs) {
      final key = _upgradeKey(config);
      final current = latestByType[key];
      if (current == null || current.upgradeLevel <= config.upgradeLevel) {
        latestByType[key] = config;
      }
    }
    final sorted = latestByType.values.toList()
      ..sort((a, b) => IslandBuildingLayout.placementPriority(b)
          .compareTo(IslandBuildingLayout.placementPriority(a)));

    final placed = <PlacedFootprint>[];
    final snapshots = <BuildingSnapshot>[];
    Offset? academyAnchor;

    for (final config in sorted) {
      if (PlazaTerraceRenderer.isPlazaBuilding(config.id)) {
        continue;
      }
      final footprint =
          BuildingFootprint.resolve(config, islandRadius: islandRadius);
      final preferred = IslandBuildingLayout.preferredAnchor(
        config,
        islandRadius: islandRadius,
      );
      var anchor = preferred;
      if (config.id == 'growth_academy') {
        anchor = _resolveAcademyAnchor(footprint);
      } else if (!IslandBuildingLayout.usesFixedAnchor(config.id)) {
        anchor = IslandBuildingLayout.resolveAnchor(
          config: config,
          preferred: preferred,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        );
      }
      if (!IslandBuildingLayout.usesFixedAnchor(config.id) &&
          (!IslandBuildingLayout.isZoneValidForBuilding(
                config: config,
                anchor: anchor,
                footprint: footprint,
                academyAnchor: academyAnchor,
              ) ||
              IslandBuildingLayout.collisionOverlapsPlaced(
                anchor,
                footprint,
                placed,
              ))) {
        anchor = IslandBuildingLayout.resolveAnchor(
          config: config,
          preferred: preferred,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        );
      }
      anchor = _finalizeAnchor(
        config: config,
        anchor: anchor,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      );
      anchor = _coerceValidAnchor(
        config: config,
        anchor: anchor,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      );
      if (!IslandBuildingLayout.isZoneValidForBuilding(
        config: config,
        anchor: anchor,
        footprint: footprint,
        academyAnchor: academyAnchor,
      )) {
        anchor = _coerceValidAnchor(
          config: config,
          anchor: IslandBuildingLayout.safeFallbackAnchor(config),
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        );
      }
      if (config.id != 'harbor_pier' && config.id != 'starter_stone') {
        final occupancy = IslandBuildingLayout.occupancyRect(anchor, footprint);
        if (occupancy.overlaps(MainIslandPlacementZones.protagonistExclusion)) {
          anchor = IslandBuildingLayout.safeFallbackAnchor(config);
          if (IslandBuildingLayout.occupancyRect(anchor, footprint)
              .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
            anchor = const Offset(0.28, 0.40);
          }
        }
      }
      if (config.id == 'dream_observatory') {
        if (anchor.dx >= 0.59 ||
            !IslandBuildingLayout.isZoneValidForBuilding(
              config: config,
              anchor: anchor,
              footprint: footprint,
              academyAnchor: academyAnchor,
            )) {
          anchor = const Offset(0.56, 0.36);
        }
        if (academyAnchor != null &&
            (anchor - academyAnchor).distance < 0.08) {
          anchor = const Offset(0.58, 0.36);
        }
      }
      if (config.id == 'growth_academy') {
        academyAnchor = anchor;
      }
      placed.add(PlacedFootprint(anchor: anchor, footprint: footprint));
      snapshots.add(
        BuildingSnapshot(
          definitionId: config.id,
          level: config.upgradeLevel,
          anchor: anchor,
          zone: config.zone,
          type: config.type,
          size: footprint,
          sprite: config.sprite,
          animation: config.animation,
          interactionType: config.interactionType,
          displayName: BuildingDisplayNames.nameFor(
            config.id,
            fallback: config.name,
          ),
          unlockLevel: config.unlockLevel,
        ),
      );
    }

    return snapshots..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
  }

  Offset _resolveAcademyAnchor(Offset footprint) {
    for (var y = 0.28; y <= 0.36; y += 0.008) {
      final candidate = Offset(0.50, y);
      if (BuildingFootprint.isFullyOnGrowthIsland(candidate, footprint)) {
        return candidate;
      }
    }
    return const Offset(0.50, 0.30);
  }

  String _upgradeKey(growth.BuildingConfig config) {
    if (config.type == 'house') return 'growth_house';
    if (config.type == 'lighthouse' || config.type == 'lighthouse_base') {
      return 'lighthouse';
    }
    return config.id;
  }

  Offset _finalizeAnchor({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    final candidates = <Offset>[
      IslandBuildingLayout.safeFallbackAnchor(config),
      IslandPlacement.clampToGrowthIsland(config.position, inset: 0.86),
      if (config.type == 'observatory') const Offset(0.68, 0.36),
      if (config.type == 'house') const Offset(0.28, 0.40),
      const Offset(0.72, 0.38),
      const Offset(0.28, 0.44),
      const Offset(0.24, 0.54),
      const Offset(0.32, 0.58),
    ];
    if (_isResolvedPlacementValid(
      config: config,
      anchor: anchor,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return anchor;
    }
    for (final candidate in candidates) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    for (var y = 0.24; y <= 0.68; y += 0.008) {
      for (var x = 0.22; x <= 0.78; x += 0.008) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isResolvedPlacementValid(
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

    final fallback = IslandBuildingLayout.safeFallbackAnchor(config);
    if (_isResolvedPlacementValid(
      config: config,
      anchor: fallback,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return fallback;
    }

    for (var y = 0.24; y <= 0.68; y += 0.006) {
      for (var x = 0.22; x <= 0.78; x += 0.006) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isResolvedPlacementValid(
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

    final hardened = _findBestFallbackAnchor(
      config: config,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (hardened != null) return hardened;

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    return hardened ??
        (config.type == 'observatory'
            ? const Offset(0.56, 0.36)
            : config.type == 'clocktower'
                ? const Offset(0.58, 0.34)
                : IslandBuildingLayout.safeFallbackAnchor(config));
  }

  static const _emergencyAnchors = <Offset>[
    Offset(0.30, 0.38),
    Offset(0.70, 0.38),
    Offset(0.34, 0.38),
    Offset(0.62, 0.36),
    Offset(0.38, 0.36),
    Offset(0.58, 0.34),
  ];

  Offset? _findBestFallbackAnchor({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    Offset? best;
    var bestDistance = double.infinity;
    final preferred = IslandBuildingLayout.safeFallbackAnchor(config);
    for (var y = 0.24; y <= 0.68; y += 0.004) {
      for (var x = 0.22; x <= 0.78; x += 0.004) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (!_isResolvedPlacementValid(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
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

  Offset _coerceValidAnchor({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (_isResolvedPlacementValid(
      config: config,
      anchor: anchor,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return anchor;
    }

    final best = _findBestFallbackAnchor(
      config: config,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (best != null) return best;

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    return switch (config.id) {
      'dream_observatory' => const Offset(0.56, 0.36),
      'memory_gallery' => const Offset(0.70, 0.38),
      'growth_clocktower' => const Offset(0.58, 0.34),
      'emotion_windchime' => const Offset(0.32, 0.38),
      'record_shed' => const Offset(0.30, 0.40),
      'quiet_tent' => const Offset(0.30, 0.38),
      'habit_flowerbed' => const Offset(0.70, 0.38),
      _ => IslandBuildingLayout.safeFallbackAnchor(config),
    };
  }

  bool _isResolvedPlacementValid({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (!IslandBuildingLayout.isZoneValidForBuilding(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (IslandBuildingLayout.collisionOverlapsPlaced(
      anchor,
      footprint,
      placed,
    )) {
      return false;
    }
    if (config.id != 'harbor_pier' &&
        !BuildingFootprint.isFullyOnGrowthIsland(anchor, footprint)) {
      return false;
    }
    if (config.id != 'harbor_pier' && config.id != 'starter_stone') {
      final occupancy = IslandBuildingLayout.occupancyRect(anchor, footprint);
      if (occupancy.overlaps(MainIslandPlacementZones.protagonistExclusion)) {
        return false;
      }
    }
    return true;
  }
}
