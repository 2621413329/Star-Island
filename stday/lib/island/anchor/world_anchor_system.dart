import 'dart:ui';

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
    if (anchors.where((anchor) => anchor.cameraFocus).isEmpty) {
      anchors.insert(
        0,
        const WorldAnchorSnapshot(
          id: 'anchor_island_center',
          type: 'island_center',
          position: Offset(0.5, 0.58),
          visualWeight: 0.5,
          cameraFocus: true,
        ),
      );
    }
    return anchors;
  }
}
