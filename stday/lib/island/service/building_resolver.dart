import 'dart:ui';

import '../../world/engine/world_state.dart';
import '../config/building_config.dart';
import '../config/growth_island_config_models.dart' as growth;
import '../building/building_footprint.dart';
import '../placement/island_building_layout.dart';
import '../placement/island_placement.dart';
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
      final footprint =
          BuildingFootprint.resolve(config, islandRadius: islandRadius);
      final preferred = IslandBuildingLayout.preferredAnchor(
        config,
        islandRadius: islandRadius,
      );
      var anchor = IslandBuildingLayout.resolveAnchor(
        config: config,
        preferred: preferred,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      );
      if (config.id == 'growth_academy') {
        anchor = _resolveAcademyAnchor(footprint);
      } else if (!IslandBuildingLayout.isZoneValidForBuilding(
        config: config,
        anchor: anchor,
        footprint: footprint,
        academyAnchor: academyAnchor,
      )) {
        anchor = IslandBuildingLayout.findNearestZoneValidAnchor(
              config: config,
              preferred: preferred,
              footprint: footprint,
              academyAnchor: academyAnchor,
            ) ??
            anchor;
      }
      if (config.id != 'harbor_pier' &&
          !BuildingFootprint.isFullyOnGrowthIsland(anchor, footprint)) {
        anchor = IslandBuildingLayout.findNearestZoneValidAnchor(
              config: config,
              preferred: preferred,
              footprint: footprint,
              academyAnchor: academyAnchor,
            ) ??
            anchor;
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
    for (var y = 0.26; y <= 0.42; y += 0.008) {
      final candidate = Offset(0.50, y);
      if (BuildingFootprint.isFullyOnGrowthIsland(candidate, footprint)) {
        return candidate;
      }
    }
    return const Offset(0.50, 0.34);
  }

  String _upgradeKey(growth.BuildingConfig config) {
    if (config.type == 'house') return 'growth_house';
    if (config.type == 'lighthouse' || config.type == 'lighthouse_base') {
      return 'lighthouse';
    }
    return config.id;
  }
}
