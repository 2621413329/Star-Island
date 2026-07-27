import 'dart:math' as math;
import 'dart:ui';

import '../../world/engine/world_state.dart';
import '../placement/island_building_layout.dart';
import '../placement/island_placement.dart';
import '../placement/large_tree_shore_parcels.dart';
import '../placement/main_island_placement_zones.dart';
import 'decor_config.dart';

/// 装饰落点：避开主角占位、建筑 footprint 与已占用区域。
class DecorPlacementResolver {
  const DecorPlacementResolver({this.islandRadius = 1.0});

  /// 与 [IslandState.radius] / 渲染岛面缩放一致，禁止装饰落在可视岛外。
  final double islandRadius;

  /// 主角脚点（归一化）；与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = MainIslandPlacementZones.protagonistFoot;

  /// 主角占位区：装饰 occupancy 与此区域重叠则需重定位。
  static Rect get protagonistExclusionRect =>
      MainIslandPlacementZones.protagonistExclusion;

  /// 测试与旧逻辑兼容：装饰不应落在主角身后占位区。
  static Rect get protagonistRearZone => protagonistExclusionRect;

  /// 装饰之间的最小间距（归一化）。
  static const decorGap = 0.014;

  /// 草/花与建筑 footprint 的额外留白（收紧后保证岛面仍能铺开）。
  static const grassBuildingClearance = 0.028;
  static const buildingDecorClearance = 0.022;
  static const largeDecorBuildingClearance = 0.034;

  static const _decorGap = decorGap;

  /// 将已放置建筑转为装饰需避开的占用矩形（含渲染放大后的视觉区）。
  static List<Rect> buildingBlockedRegions(
      Iterable<BuildingSnapshot> buildings) {
    return [
      for (final building in buildings)
        IslandBuildingLayout.occupancyRect(
          building.anchor,
          building.size,
          buildingId: building.definitionId,
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

  /// 开槽点：铺满前中带与左右岸（学院后方不放点）。
  static const _openSlots = <Offset>[
    // 左岸前 → 中
    Offset(0.18, 0.68),
    Offset(0.22, 0.64),
    Offset(0.20, 0.58),
    Offset(0.24, 0.54),
    Offset(0.26, 0.50),
    Offset(0.28, 0.60),
    Offset(0.32, 0.66),
    Offset(0.34, 0.56),
    Offset(0.30, 0.70),
    // 右岸前 → 中
    Offset(0.82, 0.68),
    Offset(0.78, 0.64),
    Offset(0.80, 0.58),
    Offset(0.76, 0.54),
    Offset(0.74, 0.50),
    Offset(0.72, 0.60),
    Offset(0.68, 0.66),
    Offset(0.66, 0.56),
    Offset(0.70, 0.70),
    // 中前两侧（避开小人）
    Offset(0.36, 0.62),
    Offset(0.40, 0.68),
    Offset(0.60, 0.68),
    Offset(0.64, 0.62),
    Offset(0.38, 0.54),
    Offset(0.62, 0.54),
    Offset(0.42, 0.58),
    Offset(0.58, 0.58),
    Offset(0.44, 0.64),
    Offset(0.56, 0.64),
  ];

  /// 大树环岛缘：左右岸 + 前缘错开，避免叠成一坨。
  static const _edgeTreeSlots = <Offset>[
    Offset(0.14, 0.48),
    Offset(0.16, 0.58),
    Offset(0.18, 0.68),
    Offset(0.30, 0.72),
    Offset(0.70, 0.72),
    Offset(0.82, 0.68),
    Offset(0.84, 0.58),
    Offset(0.86, 0.48),
  ];

  /// 每棵大树独占岸线扇区（弧度，0=+X 右岸，π/2=+Y 前缘）。
  static const _treeShoreSectorById = <String, (double center, double halfWidth)>{
    'tree_large_01': (2.95, 0.18),
    'tree_large_01b': (3.55, 0.18),
    'tree_large_01c': (1.95, 0.18),
    'life_tree_01': (3.70, 0.16),
    'tree_large_02': (0.20, 0.18),
    'tree_large_02b': (-0.40, 0.18),
    'tree_large_02c': (1.20, 0.18),
  };

  static bool _isLargeTree(DecorConfig config) =>
      config.id.startsWith('tree_large') || config.id == 'life_tree_01';

  /// 对外：是否为大树（管理器优先落点 / 失败则跳过）。
  static bool isLargeTree(DecorConfig config) => _isLargeTree(config);

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
        final aTree = _isLargeTree(a);
        final bTree = _isLargeTree(b);
        if (aTree != bTree) return aTree ? -1 : 1;
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

      final Offset? candidate;
      if (_isLargeTree(config)) {
        candidate = resolveLargeTree(
          config,
          occupied,
          randomSeed: config.id.hashCode,
          buildings: buildings,
        );
        if (candidate == null) continue;
      } else {
        var resolved = _finalizeGroundPosition(
          config,
          _resolveGroundPosition(config, occupied, buildings: buildings),
          occupied,
          buildings: buildings,
        );
        resolved ??= resolveOne(
          config,
          occupied,
          randomSeed: config.id.hashCode,
          buildings: buildings,
        );
        if (!_isValidGroundPosition(config, resolved, occupied,
            buildings: buildings)) {
          final clamped = IslandPlacement.clampToGrowthIsland(
            resolved,
            inset: _surfaceInsetFor(config),
            islandRadius: islandRadius,
          );
          if (!_isValidGroundPosition(config, clamped, occupied,
              buildings: buildings)) {
            continue;
          }
          resolved = clamped;
        }
        candidate = resolved;
      }
      positions[config.id] = candidate;
      occupied.add(_paddedOccupancyRect(config, candidate));
    }

    return positions;
  }

  /// 为单个装饰解析落点（升级解锁时随机，需传入 seed 保证可复现）。
  ///
  /// 大树请用 [resolveLargeTree]：找不到合法环岛点时返回 null，不做坐标回退。
  Offset? resolveOneOrNull(
    DecorConfig config,
    List<Rect> occupied, {
    required int randomSeed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    if (_isLargeTree(config)) {
      final tree = resolveLargeTree(
        config,
        occupied,
        randomSeed: randomSeed,
        buildings: buildings,
      );
      if (tree != null) return tree;
      throw StateError(
        'Large tree ${config.id} has no valid shore slot; '
        'do not use resolveOne fallback for trees.',
      );
    }
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

    final open = [..._openSlots]..shuffle(rng);
    open.sort((a, b) => b.dy.compareTo(a.dy));
    for (final slot in open) {
      if (!IslandPlacement.isOnGrowthIsland(
        slot,
        inset: _surfaceInsetFor(config),
      islandRadius: islandRadius,
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

    final distant = _openSlots
        .where((slot) => !_conflictsWithProtagonist(slot, config))
        .fold<Offset?>(null, (best, slot) {
      if (!_isValidGroundPosition(config, slot, blocked,
          buildings: buildings)) {
        return best;
      }
      if (best == null) return slot;
      return (slot - protagonistFoot).distanceSquared >
              (best - protagonistFoot).distanceSquared
          ? slot
          : best;
    });
    final clampedFallback = IslandPlacement.clampToGrowthIsland(
      distant ?? const Offset(0.28, 0.62),
      inset: _surfaceInsetFor(config),
            islandRadius: islandRadius,
          );
    return _finalizeGroundPosition(
      config,
      clampedFallback,
      blocked,
      seed: randomSeed,
      buildings: buildings,
    );
  }

  Offset resolveOne(
    DecorConfig config,
    List<Rect> occupied, {
    required int randomSeed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final resolved = resolveOneOrNull(
      config,
      occupied,
      randomSeed: randomSeed,
      buildings: buildings,
    );
    if (resolved != null) return resolved;
    throw StateError(
      'Decor ${config.id} has no valid ground slot; '
      'do not use unchecked fallback placement.',
    );
  }

  /// 大树专用：独占岸线极角槽 + 本扇区微移；失败返回 null（不回退叠点）。
  Offset? resolveLargeTree(
    DecorConfig config,
    List<Rect> occupied, {
    required int randomSeed,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    if (!_isLargeTree(config)) {
      return resolveOne(
        config,
        occupied,
        randomSeed: randomSeed,
        buildings: buildings,
      );
    }

    final exclusive = LargeTreeShoreParcels.shoreSlot(
      config.id,
      islandRadius: islandRadius,
    );
    final candidates = <Offset>[
      exclusive,
      ..._treeNudges(exclusive, randomSeed),
      ..._shoreSectorSamples(config.id, randomSeed),
    ];

    // 0=完整校验；1=缩小建筑清场；2=放宽建筑清场，但仍强制树间距。
    for (var softness = 0; softness <= 2; softness++) {
      for (final raw in candidates) {
        final probe = IslandPlacement.clampToGrowthIsland(
          raw,
          inset: _surfaceInsetFor(config),
          islandRadius: islandRadius,
        );
        if (_isValidLargeTreePosition(
          config,
          probe,
          occupied,
          buildings: buildings,
          softness: softness,
        )) {
          return probe;
        }
      }
      for (final shore in _shoreSectorSamples(
        config.id,
        randomSeed + softness * 97,
      )) {
        if (_isValidLargeTreePosition(
          config,
          shore,
          occupied,
          buildings: buildings,
          softness: softness,
        )) {
          return shore;
        }
      }
    }
    return null;
  }

  List<Offset> _treeNudges(Offset base, int seed) {
    final rng = math.Random(seed);
    return [
      for (var i = 0; i < 8; i++)
        base +
            Offset(
              (rng.nextDouble() - 0.5) * 0.04,
              (rng.nextDouble() - 0.5) * 0.03,
            ),
      base + const Offset(0.02, 0.015),
      base + const Offset(-0.02, 0.015),
      base + const Offset(0.015, -0.015),
      base + const Offset(-0.015, 0.02),
    ];
  }

  /// 在该大树独占扇区内沿岛缘采样（禁止跨扇区抢点）。
  List<Offset> _shoreSectorSamples(String treeId, int seed) {
    final sector = _treeShoreSectorById[treeId];
    final angleCenter =
        LargeTreeShoreParcels.shoreAngleByTreeId[treeId] ?? sector?.$1;
    if (angleCenter == null) return const [];
    final half = sector?.$2 ?? 0.22;
    final rng = math.Random(seed);
    final out = <Offset>[];
    const samples = 16;
    final scale = IslandPlacement.effectiveIslandRadius(islandRadius);
    final polar = LargeTreeShoreParcels.shorePolarByTreeId[treeId];
    final radialBase = polar?.$2 ?? 0.92;
    for (var i = 0; i < samples; i++) {
      final t = (i / (samples - 1)) * 2 - 1;
      final angle =
          angleCenter + t * half + (rng.nextDouble() - 0.5) * 0.03;
      final radial = radialBase * (0.94 + rng.nextDouble() * 0.08);
      final rx =
          IslandPlacement.growthRadiusX * 0.84 * scale * radial;
      final ry =
          IslandPlacement.growthRadiusY * 0.84 * scale * radial;
      final probe = Offset(
        IslandPlacement.center.dx + math.cos(angle) * rx,
        IslandPlacement.center.dy + math.sin(angle) * ry,
      );
      if (probe.dy < MainIslandPlacementZones.academyDefaultAnchor.dy + 0.02) {
        continue;
      }
      out.add(probe);
    }
    return out;
  }

  bool _tooCloseToOtherLargeTrees(
    Offset position,
    DecorConfig config,
    List<Rect> occupied,
  ) {
    // 大树脚点最小间距（归一化）；随半径缩放后仍靠槽位保证。
    const minDist = 0.095;
    final self = _paddedOccupancyRect(config, position);
    for (final other in occupied) {
      // 与其它大树脚垫 / 较大占地比间距。
      if (other.width < 0.06 && other.height < 0.03) continue;
      final dx = self.center.dx - other.center.dx;
      final dy = self.center.dy - other.center.dy;
      if (dx * dx + dy * dy < minDist * minDist) return true;
    }
    return false;
  }

  bool _isValidLargeTreePosition(
    DecorConfig config,
    Offset position,
    List<Rect> occupied, {
    Iterable<BuildingSnapshot> buildings = const [],
    required int softness,
  }) {
    if (!IslandPlacement.isOnGrowthIsland(
      position,
      inset: _surfaceInsetFor(config),
      islandRadius: islandRadius,
    )) {
      return false;
    }
    final academyAnchor = _academyAnchorFrom(buildings);
    if (position.dy < academyAnchor.dy + 0.01) return false;
    if (_conflictsWithProtagonist(position, config)) return false;

    final occupancy = _paddedOccupancyRect(config, position);
    if (MainIslandPlacementZones.overlapsForbiddenGround(
      occupancy,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }

    // 始终避开已占用与其它大树间距，杜绝叠点回退。
    if (_overlapsOccupied(position, config, occupied)) return false;
    if (_tooCloseToOtherLargeTrees(position, config, occupied)) {
      return false;
    }

    // softness 2：仅放宽建筑清场。
    if (softness >= 2) return true;

    if (buildings.isEmpty) return true;
    final clearance = softness == 0
        ? largeDecorBuildingClearance
        : (buildingDecorClearance * 0.5);
    final regions = buildingBlockedRegions(buildings)
        .map((rect) => rect.inflate((clearance - _decorGap).clamp(0, 1)))
        .toList(growable: false);
    if (regions.any((o) => _meaningfullyOverlaps(o, occupancy))) {
      return false;
    }
    return true;
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
            islandRadius: islandRadius,
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
            islandRadius: islandRadius,
          );
      if (_isValidGroundPosition(config, candidate, occupied,
          buildings: buildings)) {
        return candidate;
      }
    }
    return position;
  }

  Offset _academyAnchorFrom(Iterable<BuildingSnapshot> buildings) {
    for (final building in buildings) {
      if (building.definitionId == 'growth_academy') {
        return building.anchor;
      }
    }
    return MainIslandPlacementZones.academyDefaultAnchor;
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
    islandRadius: islandRadius,
    )) {
      return false;
    }
    if (_conflictsWithProtagonist(position, config)) return false;
    final academyAnchor = _academyAnchorFrom(buildings);
    final occupancy = _paddedOccupancyRect(config, position);
    if (MainIslandPlacementZones.overlapsForbiddenGround(
      occupancy,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    // 学院后方整带：锚点本身也禁止。
    if (position.dy < academyAnchor.dy - 0.01) return false;
    if (_conflictsWithBuildingFoot(config, position, buildings)) return false;
    if (_overlapsOccupied(position, config, occupied)) return false;
    if (!_isLargeTree(config) &&
        LargeTreeShoreParcels.overlapsAnyParcel(occupancy)) {
      return false;
    }
    if (buildings.isNotEmpty) {
      final grassBlocks = buildingBlockedRegionsFor(config, buildings);
      if (grassBlocks.any((o) => _meaningfullyOverlaps(o, occupancy))) {
        return false;
      }
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
    // 大树不走此回退链；由 resolveLargeTree 负责。
    if (_isLargeTree(config)) {
      return Offset(config.x, config.y);
    }

    final defaultPos = Offset(config.x, config.y);
    if (_isValidGroundPosition(config, defaultPos, occupied,
        buildings: buildings)) {
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
        const Offset(0.30, 0.62);
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
      // 大树贴岸：inset 略松，避免缘位被判出岛。
      DecorCategory.tree => _isLargeTree(config) ? 0.84 : 0.78,
      DecorCategory.pond => 0.72,
      DecorCategory.bush || DecorCategory.special => 0.76,
      DecorCategory.stone => 0.78,
      _ => 0.82,
    };
  }

  bool _conflictsWithBuildingFoot(
    DecorConfig config,
    Offset position,
    Iterable<BuildingSnapshot> buildings,
  ) {
    if (!_isFineGroundDecor(config)) return false;
    final exclusions = IslandBuildingLayout.buildingFootGrassExclusions(buildings);
    return exclusions.any((rect) => rect.contains(position));
  }

  bool _conflictsWithProtagonist(Offset p, DecorConfig config) {
    // 硬禁区：任何地面装饰锚点都不可进入。
    if (protagonistExclusionRect.contains(p)) return true;
    final exclusion = _isFineGroundDecor(config)
        ? MainIslandPlacementZones.protagonistSoftExclusion
        : protagonistExclusionRect;
    return _paddedOccupancyRect(config, p).overlaps(exclusion);
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
    return hit.width > 0.0004 && hit.height > 0.0004;
  }

  Rect _occupancyRect(DecorConfig config, Offset p) {
    final isLargeTree = _isLargeTree(config);
    // 大树占位用贴地脚垫（勿用树冠高盒），否则前后岸树会因树冠框误判重叠。
    if (isLargeTree) {
      return Rect.fromCenter(
        center: p,
        width: 0.078,
        height: 0.042,
      );
    }
    final scaleBoost = (config.scale * 0.55).clamp(0.55, 1.15);
    final w = switch (config.category) {
          DecorCategory.tree => 0.075,
          DecorCategory.bush => 0.07,
          DecorCategory.stone => 0.065,
          DecorCategory.flower => 0.05,
          DecorCategory.pond => 0.12,
          DecorCategory.special => 0.065,
          _ => 0.05,
        } *
        scaleBoost;
    final h = w * 1.05;
    return Rect.fromCenter(
      center: Offset(p.dx, p.dy - h * 0.30),
      width: w,
      height: h,
    );
  }

  Rect _paddedOccupancyRect(DecorConfig config, Offset p) {
    final pad = _isLargeTree(config) ? 0.006 : _decorGap;
    return _occupancyRect(config, p).inflate(pad);
  }

  Offset? _findOpenSlot(
    DecorConfig config,
    List<Rect> occupied, {
    bool forceRear = false,
    Iterable<BuildingSnapshot> buildings = const [],
  }) {
    final rng = math.Random(config.id.hashCode);
    final slots = <Offset>[];
    if (_isLargeTree(config)) {
      slots.addAll(_edgeTreeSlots);
    }
    slots.addAll(_openSlots);
    if (forceRear) {
      slots.sort((a, b) => a.dy.compareTo(b.dy));
    } else {
      // 优先前侧空地，再轻微打散同带内左右岸。
      slots.sort((a, b) {
        final byFront = b.dy.compareTo(a.dy);
        if (byFront != 0) return byFront;
        return rng.nextBool() ? 1 : -1;
      });
    }
    final academyY = MainIslandPlacementZones.academyDefaultAnchor.dy;
    for (final slot in slots) {
      // forceRear 改为“侧岸后带”，仍禁止学院正后方。
      if (forceRear && slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (slot.dy < academyY + 0.01) continue;
      if (!IslandPlacement.isOnGrowthIsland(
        slot,
        inset: _surfaceInsetFor(config),
      islandRadius: islandRadius,
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
    final academyY = MainIslandPlacementZones.academyDefaultAnchor.dy;
    final slots = <Offset>[];
    slots.addAll(_openSlots);
    for (final slot in slots) {
      if (slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (slot.dy < academyY + 0.01) continue;
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
    final academyY = _academyAnchorFrom(buildings).dy;
    // 在岛面椭圆内均匀探测，优先铺开前中带，避免挤在学院旁。
    for (var attempt = 0; attempt < 320; attempt++) {
      final x = 0.14 + rng.nextDouble() * 0.72;
      final yBias = rng.nextDouble();
      // 约 70% 样本落在前中带 (0.54–0.72)。
      final y = yBias < 0.70
          ? 0.54 + rng.nextDouble() * 0.18
          : academyY + 0.04 + rng.nextDouble() * 0.16;
      final probe = IslandPlacement.clampToGrowthIsland(
        Offset(x, y),
        inset: _surfaceInsetFor(config),
            islandRadius: islandRadius,
          );
      if (probe.dy < academyY + 0.01) continue;
      if (_isValidGroundPosition(config, probe, occupied,
          buildings: buildings)) {
        return probe;
      }
    }
    return null;
  }
}
