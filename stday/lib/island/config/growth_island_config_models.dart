import 'dart:ui';

class RangeDouble {
  const RangeDouble(this.min, this.max);

  final double min;
  final double max;
}

class IslandLevelConfig {
  const IslandLevelConfig({
    required this.level,
    required this.islandRadius,
    required this.unlockZones,
    required this.unlockBuildings,
    required this.unlockDecorations,
    required this.unlockPaths,
    required this.unlockEffects,
    required this.unlockWeather,
    required this.requiredGrowthScore,
  });

  final int level;
  final double islandRadius;
  final List<String> unlockZones;
  final List<String> unlockBuildings;
  final List<String> unlockDecorations;
  final List<String> unlockPaths;
  final List<String> unlockEffects;
  final String unlockWeather;
  final int requiredGrowthScore;
}

class BuildingConfig {
  const BuildingConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.unlockLevel,
    required this.zone,
    required this.position,
    required this.size,
    required this.sprite,
    required this.animation,
    required this.interactionType,
    required this.upgradeLevel,
  });

  final String id;
  final String name;
  final String type;
  final int unlockLevel;
  final String zone;
  final Offset position;
  final Offset size;
  final String sprite;
  final String animation;
  final String interactionType;
  final int upgradeLevel;
}

class ZoneConfig {
  const ZoneConfig({
    required this.id,
    required this.name,
    required this.priority,
    required this.bounds,
    required this.allowedBuildings,
    required this.allowedDecorations,
  });

  final String id;
  final String name;
  final int priority;
  final Rect bounds;
  final List<String> allowedBuildings;
  final List<String> allowedDecorations;
}

class PathConfig {
  const PathConfig({
    required this.id,
    required this.unlockLevel,
    required this.startNode,
    required this.endNode,
    required this.pathType,
    required this.width,
  });

  final String id;
  final int unlockLevel;
  final String startNode;
  final String endNode;
  final String pathType;
  final double width;
}

class AnchorConfig {
  const AnchorConfig({
    required this.id,
    required this.anchorBuildingId,
    required this.visualWeight,
    required this.cameraFocus,
  });

  final String id;
  final String anchorBuildingId;
  final double visualWeight;
  final bool cameraFocus;
}
