import 'dart:math' as math;
import 'dart:ui';

import '../../island/anchor/world_anchor_system.dart';
import '../../island/placement/island_building_layout.dart';
import '../../island/placement/island_placement.dart';
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
    final decorationConfigs =
        configRepository.resolveDecorations(levelConfig.unlockDecorations);

    final buildings = buildingResolver.resolveConfigured(
      configs: buildingConfigs,
      islandRadius: levelConfig.islandRadius,
    );
    final decorations = _buildDecorations(decorationConfigs, zones, buildings);
    final flora = _buildFlora(decorations);
    final paths = const <PathSnapshot>[];
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
        elevation: input.compact ? 0.070 : 0.075,
        prosperityTier: _visualTier(levelConfig.level),
        radius: levelConfig.islandRadius,
      ),
      zones: zones.map(_zoneSnapshot).toList(growable: false),
      buildings: buildings,
      decorations: decorations,
      paths: paths,
      effects: effects,
      anchors: anchors,
      flora: flora,
      characters: [_buildProtagonist(input, levelConfig)],
      environment: environment,
      companionGender: input.companionGender,
    );
  }

  List<DecorationSnapshot> _buildDecorations(
    List<DecorationConfig> configs,
    List<ZoneConfig> zones,
    List<BuildingSnapshot> buildings,
  ) {
    final zoneById = {for (final zone in zones) zone.id: zone};
    final out = <DecorationSnapshot>[];
    for (final config in configs) {
      if (config.id == 'bridge_small') continue;
      final zone = zoneById[config.zone];
      if (zone == null) continue;
      final count = math.max(1, (config.density * 8).round());
      final random = math.Random(config.randomSeed);
      final buildingMargin = switch (config.type) {
        'tree' => 0.042,
        _ => 0.026,
      };
      for (var index = 0; index < count; index++) {
        final position = _randomDecorationPosition(
          zone: zone,
          random: random,
          inset: _insetForType(config.type),
          buildings: buildings,
          buildingMargin: buildingMargin,
        );
        if (position == null) continue;
        final scale = _lerpRange(config.scaleRange, random.nextDouble());
        final rotation = _lerpRange(config.rotationRange, random.nextDouble());
        out.add(DecorationSnapshot(
          id: '${config.id}_$index',
          configId: config.id,
          type: config.type,
          zone: config.zone,
          position: position,
          asset: config.asset,
          animation: config.animation,
          scale: scale,
          rotation: rotation,
        ));
      }
    }
    return out;
  }

  Offset? _randomDecorationPosition({
    required ZoneConfig zone,
    required math.Random random,
    required double inset,
    required List<BuildingSnapshot> buildings,
    required double buildingMargin,
  }) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final candidate = IslandPlacement.randomInZone(
        zone.bounds,
        random,
        inset: inset,
      );
      // 装饰锚点为底部接地点，不得落在建筑占地内。
      if (!IslandBuildingLayout.overlapsAnyBuilding(
        candidate,
        buildings,
        margin: buildingMargin,
      )) {
        return candidate;
      }
    }
    return null;
  }

  List<FloraSnapshot> _buildFlora(List<DecorationSnapshot> decorations) {
    return decorations
        .map((decoration) => FloraSnapshot(
              floraId: decoration.id,
              kind: _floraKind(decoration.type),
              position: decoration.position,
              growth: decoration.scale,
              zone: decoration.zone,
              asset: decoration.asset,
              animation: decoration.animation,
              rotation: decoration.rotation,
            ))
        .toList(growable: false);
  }

  FloraKind _floraKind(String type) {
    return switch (type) {
      'tree' => FloraKind.tree,
      'flower' => FloraKind.flower,
      'grass' => FloraKind.grass,
      _ => FloraKind.bush,
    };
  }

  List<PathSnapshot> _buildPaths(
    List<PathConfig> configs,
    List<BuildingSnapshot> buildings,
  ) {
    final byId = {
      for (final building in buildings) building.definitionId: building
    };
    final upgradedHouse = byId['growth_house_lv2'];
    if (upgradedHouse != null) {
      byId['growth_house'] = upgradedHouse;
    }
    final academy = byId['growth_academy'];
    if (academy != null) {
      byId['growth_house'] = academy;
      byId['growth_house_lv2'] = academy;
      byId['memory_fountain'] = academy;
      byId['growth_clocktower'] = academy;
    }
    final out = <PathSnapshot>[];
    for (final config in configs) {
      final start = byId[config.startNode]?.anchor ?? const Offset(0.5, 0.5);
      final end = byId[config.endNode]?.anchor ?? start;
      out.add(PathSnapshot(
        id: config.id,
        start: start,
        end: end,
        pathType: config.pathType,
        width: config.width,
      ));
    }
    return out;
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

  double _lerpRange(RangeDouble range, double t) {
    return range.min + (range.max - range.min) * t;
  }

  double _insetForType(String type) => switch (type) {
        'tree' => 0.82,
        'grass' => 0.9,
        'flower' => 0.88,
        _ => 0.86,
      };
}
