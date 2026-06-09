import '../../world/engine/world_state.dart';
import '../config/building_config.dart';
import '../config/growth_island_config_models.dart' as growth;

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
  }) {
    final latestByType = <String, growth.BuildingConfig>{};
    for (final config in configs) {
      final key = _upgradeKey(config);
      final current = latestByType[key];
      if (current == null || current.upgradeLevel <= config.upgradeLevel) {
        latestByType[key] = config;
      }
    }
    return latestByType.values.map(_toSnapshot).toList(growable: false)
      ..sort((a, b) => a.anchor.dy.compareTo(b.anchor.dy));
  }

  String _upgradeKey(growth.BuildingConfig config) {
    if (config.type == 'house') return 'growth_house';
    return config.id;
  }

  BuildingSnapshot _toSnapshot(growth.BuildingConfig config) {
    return BuildingSnapshot(
      definitionId: config.id,
      level: config.upgradeLevel,
      anchor: config.position,
      zone: config.zone,
      type: config.type,
      size: config.size,
      sprite: config.sprite,
      animation: config.animation,
      interactionType: config.interactionType,
    );
  }
}
