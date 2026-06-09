import '../../world/engine/world_state.dart';
import '../config/growth_island_config_models.dart';

class WorldAnchorSystem {
  const WorldAnchorSystem();

  List<WorldAnchorSnapshot> resolve({
    required List<AnchorConfig> configs,
    required List<BuildingSnapshot> buildings,
  }) {
    final buildingsById = {
      for (final building in buildings) building.definitionId: building,
    };
    final anchors = <WorldAnchorSnapshot>[];
    for (final config in configs) {
      final building = buildingsById[config.anchorBuildingId];
      if (building == null) continue;
      anchors.add(WorldAnchorSnapshot(
        id: config.id,
        type: config.anchorBuildingId,
        position: building.anchor,
        visualWeight: config.visualWeight,
        cameraFocus: config.cameraFocus,
      ));
    }
    anchors.sort((a, b) => b.visualWeight.compareTo(a.visualWeight));
    return anchors;
  }
}
