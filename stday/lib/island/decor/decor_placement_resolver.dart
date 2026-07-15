import 'dart:math' as math;
import 'dart:ui';

import '../../world/engine/world_state.dart';
import '../placement/island_building_layout.dart';
import '../placement/island_placement.dart';
import '../placement/main_island_placement_zones.dart';
import 'decor_config.dart';

/// 装饰落点：避开主角占位、建筑 footprint 与已占用区域。
class DecorPlacementResolver {
  const DecorPlacementResolver();

  /// 主角脚点（归一化）；与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = MainIslandPlacementZones.protagonistFoot;

  /// 主角占位区：装饰 occupancy 与此区域重叠则需重定位。
  static Rect get protagonistExclusionRect =>
      MainIslandPlacementZones.protagonistExclusion;

  /// 测试与旧逻辑兼容：装饰不应落在主角身后占位区。
  static Rect get protagonistRearZone => protagonistExclusionRect;

  /// 装饰之间的最小间距（归一化）。
  static const decorGap = 0.014;

  /// 草/花与建筑 footprint 的额外留白（#8 建筑旁错草）。
  static const grassBuildingClearance = 0.044;
  static const buildingDecorClearance = 0.030;
  static const largeDecorBuildingClearance = 0.052;

  static const _decorGap = decorGap;

  /// 将已放置建筑转为装饰需避开的占用矩形。
  static List<Rect> buildingBlockedRegions(
      Iterable<BuildingSnapshot> buildings) {
    return [
      for (final building in buildings)
        IslandBuildingLayout.occupancyRect(
          building.anchor,
          building.size,
        ).inflate(_decorGap),
    ];
  }

  static List<Rect> buildingBlockedRegionsFor(
      DecorConfig config, Iterable<BuildingSnapshot> buildings) {
    final regions = buildingBlockedRegions(buildings);
    final clearance = _buildingClearanceFor(config);
    return regions
        .map(
          (rect) =>
              rect.inflate((clearance - _decorGap).clamp(0, 1).toDouble()),
        )
        .toList(growable: false);
  }

  static double _buildingClearanceFor(DecorConfig config) {
    return switch (config.category) {
      DecorCategory.grass || DecorCategory.flower => grassBuildingClearance,
      DecorCategory.tree || DecorCategory.pond => largeDecorBuildingClearance,
      _ => buildingDecorClearance,
    };
  }

  static bool _isFineGroundDecor(DecorConfig config) {
    return config.category == DecorCategory.grass ||
        config.category == DecorCategory.flower;
  }

  static const _openSlots = <Offset>[
    Offset(0.22, 0.44),
    Offset(0.30, 0.46),
    Offset(0.38, 0.48),
    Offset(0.46, 0.47),
    Offset(0.54, 0.47),
    Offset(0.62, 0.48),
    Offset(0.70, 0.46),
    Offset(0.78, 0.44),
    Offset(0.26, 0.52),
    Offset(0.34, 0.51),
    Offset(0.66, 0.51),
    Offset(0.74, 0.52),
    Offset(0.24, 0.58),
    Offset(0.76, 0.58),
    Offset(0.22, 0.64),
    Offset(0.78, 0.64),
    Offset(0.26, 0.60),
    Offset(0.74, 0.60),
    Offset(0.30, 0.66),
    Offset(0.70, 0.66),
    Offset(0.34, 0.62),
    Offset(0.66, 0.62),
    Offset(0.40, 0.68),
    Offset(0.60, 0.68),
  ];

  Map<String, Offset> resolve(
    List<DecorConfig> configs, {
    Iterable<BuildingSnapshot> buildings = const [],
    List<Rect> blockedRegions = const [],
  }) {
    final positions = <String, Offset>{};
    final occupied = <Rect>[
      ...blockedRegions,
      ...buildingBlockedRegions(buildings),
    ];

    final sorted = [...configs]..sort((a, b) {
        final aConflict = _conflictsWithProtagonist(Offset(a.x, a.y), a);
        final bConflict = _conflictsWithProtagonist(Offset(b.x, b.y), b);
        if (aConflict != bConflict) return aConflict ? -1 : 1;
        return a.unlockLevel.compareTo(b.unlockLevel);
      });

    for (final config in sorted) {
      if (_isSkyDecor(config)) {
        positions[config.id] = Offset(config.x, config.y);
        continue;
      }

      var candidate = _finalizeGroundPosition(
        config,
        _resolveGroundPosition(config, occupied, buildings: buildings),
        occupied,
        buildings: buildings,
      );
      candidate ??= resolveOne(
        config,
        occupied,
        randomSeed: config.id.hashCode,
        buildings: buildings,
      );
      if (!_isValidGroundPosition(config, candidate, occupied,
          buildings: buildings)) {
        continue;
      }
      positions[config.id] = candidate;
      occupied.add(_paddedOccupancyRect(config, candidate));
    }

    return positions;
  }

  /// 为单个装饰解析落点（升级解锁时随机，需传入 seed 保证可复现）。
  Offset resolveOne(
    DecorConfig config,
    List<Rect> occupied, {
    required int randomSeed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final blocked = [
      ...occupied,
      ...buildingBlockedRegionsFor(config, buildings),
    ];
    if (_isSkyDecor(config)) {
      return Offset(config.x, config.y);
    }
    final rng = math.Random(randomSeed);
    final defaultPos = Offset(config.x, config.y);
    if (_isValidGroundPosition(config, defaultPos, blocked,
        buildings: buildings)) {
      return defaultPos;
    }

    final slots = <Offset>[];
    slots.addAll([..._openSlots]..shuffle(rng));
    for (final slot in slots) {
      if (!IslandPlacement.isOnGrowthIsland(
        slot,
        inset: _surfaceInsetFor(config),
      )) {
        continue;
      }
      if (_conflictsWithProtagonist(slot, config)) continue;
      if (!_overlapsOccupied(slot, config, blocked)) {
        return _finalizeGroundPosition(
              config,
              slot,
              blocked,
              seed: randomSeed,
              buildings: buildings,
            ) ??
            slot;
      }
    }

    final probed = _probeNonOverlapping(
      config,
      blocked,
      seed: randomSeed,
      buildings: buildings,
    );
    if (probed != null) return probed;

    return _finalizeGroundPosition(
          config,
          defaultPos,
          blocked,
          seed: randomSeed,
          buildings: buildings,
        ) ??
        defaultPos;
  }

  Offset? _finalizeGroundPosition(
    DecorConfig config,
    Offset candidate,
    List<Rect> occupied, {
    int? seed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    if (_isValidGroundPosition(config, candidate, occupied,
        buildings: buildings)) {
      return _staggerGrassNearBuildings(
        config,
        candidate,
        occupied,
        buildings: buildings,
      );
    }

    final clamped = IslandPlacement.clampToGrowthIsland(
      candidate,
      inset: _surfaceInsetFor(config),
    );
    if (_isValidGroundPosition(config, clamped, occupied,
        buildings: buildings)) {
      return _staggerGrassNearBuildings(
        config,
        clamped,
        occupied,
        buildings: buildings,
      );
    }

    final probed = _probeNonOverlapping(
      config,
      occupied,
      seed: seed ?? config.id.hashCode,
      buildings: buildings,
    );
    if (probed != null) return probed;

    final slot = _findOpenSlot(config, occupied, buildings: buildings) ??
        _findOpenSlot(config, occupied, forceRear: true, buildings: buildings);
    if (slot != null &&
        _isValidGroundPosition(config, slot, occupied, buildings: buildings)) {
      return _staggerGrassNearBuildings(
        config,
        slot,
        occupied,
        buildings: buildings,
      );
    }

    Offset? best;
    var bestDistance = -1.0;
    for (final open in _openSlots) {
      if (!_isValidGroundPosition(config, open, occupied,
          buildings: buildings)) {
        continue;
      }
      final dist = (open - protagonistFoot).distanceSquared;
      if (dist > bestDistance) {
        bestDistance = dist;
        best = open;
      }
    }
    if (best != null) return best;

    final hash = config.id.hashCode;
    for (var idx = 0; idx < 5400; idx++) {
      final x = 0.18 + (idx % 54) * 0.012;
      final y = 0.44 + ((idx ~/ 54) % 24) * 0.012;
      final probe = Offset(x, y);
      if (_isValidGroundPosition(config, probe, occupied,
          buildings: buildings)) {
        return probe;
      }
    }

    final rng = math.Random(hash ^ occupied.length);
    for (var attempt = 0; attempt < 480; attempt++) {
      final probe = Offset(
        0.18 + rng.nextDouble() * 0.64,
        0.44 + rng.nextDouble() * 0.28,
      );
      if (_isValidGroundPosition(config, probe, occupied,
          buildings: buildings)) {
        return probe;
      }
    }

    for (var i = 0; i < _openSlots.length; i++) {
      final rotated = _openSlots[(hash + i) % _openSlots.length];
      if (_isValidGroundPosition(config, rotated, occupied,
          buildings: buildings)) {
        return rotated;
      }
    }

    return null;
  }

  Offset _staggerGrassNearBuildings(
    DecorConfig config,
    Offset position,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    if (!_isFineGroundDecor(config)) return position;
    final rng = math.Random(config.id.hashCode + 29);
    final nudges = [
      Offset(
          (rng.nextDouble() - 0.5) * 0.018, (rng.nextDouble() - 0.5) * 0.012),
      const Offset(0.014, 0.004),
      const Offset(-0.012, 0.006),
      Offset((rng.nextDouble() - 0.5) * 0.022, 0.008),
    ];
    for (final nudge in nudges) {
      final candidate = IslandPlacement.clampToGrowthIsland(
        position + nudge,
        inset: _surfaceInsetFor(config),
      );
      if (_isValidGroundPosition(config, candidate, occupied,
          buildings: buildings)) {
        return candidate;
      }
    }
    return position;
  }

  bool _isValidGroundPosition(
    DecorConfig config,
    Offset position,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    if (!IslandPlacement.isOnGrowthIsland(
      position,
      inset: _surfaceInsetFor(config),
    )) {
      return false;
    }
    if (_conflictsWithProtagonist(position, config)) return false;
    if (_overlapsOccupied(position, config, occupied)) return false;
    if (buildings.isNotEmpty) {
      final rect = _paddedOccupancyRect(config, position);
      final grassBlocks = buildingBlockedRegionsFor(config, buildings);
      if (grassBlocks.any((o) => _meaningfullyOverlaps(o, rect))) return false;
    }
    return true;
  }

  bool isValidGroundPosition(
    DecorConfig config,
    Offset position,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    return _isValidGroundPosition(
      config,
      position,
      occupied,
      buildings: buildings,
    );
  }

  Offset _resolveGroundPosition(
    DecorConfig config,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final defaultPos = Offset(config.x, config.y);
    if (!_conflictsWithProtagonist(defaultPos, config) &&
        !_overlapsOccupied(defaultPos, config, occupied)) {
      return defaultPos;
    }

    final fromSlots = _findOpenSlot(config, occupied, buildings: buildings) ??
        _findOpenSlot(config, occupied,
            forceRear: true, buildings: buildings) ??
        _rearFallback(config, occupied, buildings: buildings);
    if (fromSlots != null) return fromSlots;

    final probed = _probeNonOverlapping(config, occupied, buildings: buildings);
    if (probed != null) return probed;

    return _findOpenSlot(config, occupied, buildings: buildings) ??
        _findOpenSlot(
          config,
          occupied,
          forceRear: true,
          buildings: buildings,
        ) ??
        const Offset(0.22, 0.44);
  }

  bool isSkyDecor(DecorConfig config) {
    return _isSkyDecor(config);
  }

  Rect paddedOccupancyFor(DecorConfig config, Offset p) {
    return _paddedOccupancyRect(config, p);
  }

  bool _isSkyDecor(DecorConfig config) =>
      DecorConfigs.isMainIslandSkyDecor(config);

  double _surfaceInsetFor(DecorConfig config) {
    return switch (config.category) {
      DecorCategory.tree || DecorCategory.pond => 0.64,
      DecorCategory.bush || DecorCategory.special => 0.70,
      DecorCategory.stone => 0.74,
      _ => 0.80,
    };
  }

  bool _conflictsWithProtagonist(Offset p, DecorConfig config) {
    if (protagonistExclusionRect.contains(p)) return true;
    return _paddedOccupancyRect(config, p).overlaps(protagonistExclusionRect);
  }

  bool _overlapsOccupied(
    Offset p,
    DecorConfig config,
    List<Rect> occupied,
  ) {
    final rect = _paddedOccupancyRect(config, p);
    return occupied.any((o) => _meaningfullyOverlaps(o, rect));
  }

  bool _meaningfullyOverlaps(Rect a, Rect b) {
    if (!a.overlaps(b)) return false;
    final hit = a.intersect(b);
    return hit.width > 0.001 && hit.height > 0.001;
  }

  Rect _occupancyRect(DecorConfig config, Offset p) {
    final scaleBoost = (config.scale * 1.12).clamp(0.55, 1.85);
    final w = switch (config.category) {
          DecorCategory.tree => 0.12,
          DecorCategory.bush => 0.10,
          DecorCategory.stone => 0.09,
          DecorCategory.flower => 0.08,
          DecorCategory.pond => 0.14,
          DecorCategory.special => 0.08,
          _ => 0.07,
        } *
        scaleBoost;
    final h = w * 1.15;
    return Rect.fromCenter(
      center: Offset(p.dx, p.dy - h * 0.35),
      width: w,
      height: h,
    );
  }

  Rect _paddedOccupancyRect(DecorConfig config, Offset p) {
    return _occupancyRect(config, p).inflate(_decorGap);
  }

  Offset? _findOpenSlot(
    DecorConfig config,
    List<Rect> occupied, {
    bool forceRear = false,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final rng = math.Random(config.id.hashCode);
    final slots = <Offset>[];
    slots.addAll(_openSlots);
    if (forceRear) {
      slots.sort((a, b) => a.dy.compareTo(b.dy));
    } else {
      slots.shuffle(rng);
    }
    for (final slot in slots) {
      if (forceRear && slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (!IslandPlacement.isOnGrowthIsland(
        slot,
        inset: _surfaceInsetFor(config),
      )) {
        continue;
      }
      if (_isValidGroundPosition(config, slot, occupied,
          buildings: buildings)) {
        return slot;
      }
    }
    return null;
  }

  Offset? _rearFallback(
    DecorConfig config,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final slots = <Offset>[];
    slots.addAll(_openSlots);
    for (final slot in slots) {
      if (slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (_isValidGroundPosition(config, slot, occupied,
          buildings: buildings)) {
        return slot;
      }
    }
    return null;
  }

  Offset? _probeNonOverlapping(
    DecorConfig config,
    List<Rect> occupied, {
    int? seed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final rng = math.Random(seed ?? config.id.hashCode + 17);
    for (var ring = 0; ring < 16; ring++) {
      for (var i = 0; i < 20; i++) {
        final angle = (math.pi * 2 / 20) * i + ring * 0.15;
        final dist = 0.28 + ring * 0.045 + rng.nextDouble() * 0.035;
        final probe = IslandPlacement.clampToGrowthIsland(
          Offset(
            protagonistFoot.dx + math.cos(angle) * 0.24 * dist,
            protagonistFoot.dy - 0.07 - ring * 0.014 - rng.nextDouble() * 0.04,
          ),
          inset: _surfaceInsetFor(config),
        );
        if (_isValidGroundPosition(config, probe, occupied,
            buildings: buildings)) {
          return probe;
        }
      }
    }
    return null;
  }
}
