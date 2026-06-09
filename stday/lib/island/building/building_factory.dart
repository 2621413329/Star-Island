import 'package:flame/game.dart';

import '../../world/engine/world_state.dart';
import '../config/growth_island_configs.dart';
import 'building_asset_resolver.dart';
import 'building_render_component.dart';

class BuildingFactory {
  BuildingFactory({
    BuildingAssetResolver? assetResolver,
  }) : _assetResolver = assetResolver ?? BuildingAssetResolver();

  final BuildingAssetResolver _assetResolver;

  Future<void> preload(
    FlameGame game,
    Iterable<BuildingSnapshot> snapshots,
  ) async {
    for (final snapshot in snapshots) {
      final config = GrowthIslandConfigs.buildingById(snapshot.definitionId);
      if (config == null) continue;
      await _assetResolver.resolve(game, config);
    }
  }

  BuildingRenderComponent? create(BuildingSnapshot snapshot) {
    final config = GrowthIslandConfigs.buildingById(snapshot.definitionId);
    if (config == null) return null;
    return BuildingRenderComponent(
      config: config,
      snapshot: snapshot,
      asset: _assetResolver.cachedOrFallback(config),
    );
  }
}
