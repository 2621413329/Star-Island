import 'dart:ui';

import '../../island/anchor/world_anchor_system.dart';
import '../../island/placement/island_building_layout.dart';
import '../../core/models/character_mood.dart';
import '../../island/config/growth_island_config_models.dart';
import '../../island/config/growth_island_configs.dart';
import '../../island/config/island_visual_config.dart';
import '../../core/utils/companion_base_expression.dart';
import '../../island/service/building_resolver.dart';
import '../../world/behaviors/protagonist_behavior.dart';
import '../../world/engine/growth_world_input.dart';
import '../../world/engine/world_state.dart';
import '../../world/engine/world_state_v2.dart';
import '../../world/systems/mood_environment_controller.dart';

class IslandGenerator {
  const IslandGenerator({
    this.configRepository = const GrowthIslandConfigRepository(),
    this.buildingResolver = const BuildingResolver(),
    this.anchorSystem = const WorldAnchorSystem(),
    this.environmentController = const MoodEnvironmentController(),
  });

  final GrowthIslandConfigRepository configRepository;
  final BuildingResolver buildingResolver;
  final WorldAnchorSystem anchorSystem;
  final MoodEnvironmentController environmentController;

  WorldStateV2 generate(GrowthWorldInput input) {
    final levelConfig = configRepository.resolveLevel(input.protagonistLevel);
    final zones = configRepository.resolveZones(levelConfig.unlockZones);
    final buildingConfigs =
        configRepository.resolveBuildings(levelConfig.unlockBuildings);

    final buildings = buildingResolver.resolveConfigured(
      configs: buildingConfigs,
      islandRadius: levelConfig.islandRadius,
    );
    const paths = <PathSnapshot>[];
    final effects = _buildEffects(levelConfig.unlockEffects, buildings);
    final anchors = anchorSystem.resolve(
      configs: GrowthIslandConfigs.anchors,
      buildings: buildings,
    );
    final environment = environmentController.compute(
      input.mood,
      moodId: input.islandStyle.moodId,
      weather: input.weather,
    );

    return WorldStateV2(
      island: IslandState(
        shapeKey: IslandVisualConfig.fixedShapeKey,
        style: input.islandStyle,
        elevation: input.compact ? 0.004 : 0.006,
        prosperityTier: _visualTier(levelConfig.level),
        radius: levelConfig.islandRadius,
      ),
      zones: zones.map(_zoneSnapshot).toList(growable: false),
      buildings: buildings,
      decorations: const [],
      paths: paths,
      effects: effects,
      anchors: anchors,
      flora: const [],
      characters: [_buildProtagonist(input, levelConfig)],
      environment: environment,
      companionGender: input.companionGender,
    );
  }

  List<EffectSnapshot> _buildEffects(
    List<String> effectIds,
    List<BuildingSnapshot> buildings,
  ) {
    final center =
        buildings.isEmpty ? const Offset(0.5, 0.5) : buildings.last.anchor;
    return effectIds
        .map((id) => EffectSnapshot(id: id, type: id, anchor: center))
        .toList(growable: false);
  }

  CharacterSnapshot _buildProtagonist(
    GrowthWorldInput input,
    IslandLevelConfig levelConfig,
  ) {
    return CharacterSnapshot(
      id: 'protagonist',
      mood: input.mood,
      level: levelConfig.level,
      accessoryIds: const [],
      animationKey: 'float',
      normalizedPos: ProtagonistBehavior.defaultBase,
      expression: companionBaseExpressionFromMood(input.mood, moodId: input.moodId),
      prop: 'none',
      motion: _motion(input.mood, compact: input.compact),
      scale: input.compact ? 1.0 : 1.05,
    );
  }

  CharacterMotion _motion(CharacterMood mood, {required bool compact}) {
    final base = compact ? 2.0 : 3.4;
    return CharacterMotion(
      bobAmplitude: mood == CharacterMood.happy ? base * 0.7 : base * 0.45,
      wanderRadius: base,
      wanderSpeed: mood == CharacterMood.calm ? 0.18 : 0.24,
    );
  }

  ZoneSnapshot _zoneSnapshot(ZoneConfig config) {
    return ZoneSnapshot(
      id: config.id,
      name: config.name,
      priority: config.priority,
      bounds: config.bounds,
    );
  }

  int _visualTier(int level) {
    final normalized = ((level - 1) / 19 * 5).floor();
    return normalized.clamp(0, 5);
  }
}
