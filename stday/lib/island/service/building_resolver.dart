import 'dart:math' as math;
import 'dart:ui';

import '../../world/engine/world_state.dart';
import '../config/building_config.dart';
import '../config/growth_island_config_models.dart' as growth;
import '../building/building_footprint.dart';
import '../placement/island_building_layout.dart';
import '../placement/island_placement.dart';
import '../placement/main_island_placement_zones.dart';
import '../building/plaza_terrace_renderer.dart';
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
    final usedSlotIndexes = <int>{};

    for (final config in sorted) {
      if (PlazaTerraceRenderer.isPlazaBuilding(config.id)) {
        continue;
      }
      final footprint =
          BuildingFootprint.resolve(config, islandRadius: islandRadius);
      final preferred = IslandBuildingLayout.preferredAnchor(
        config,
        islandRadius: islandRadius,
      );

      late final Offset anchor;
      if (config.id == 'growth_academy') {
        anchor = _resolveAcademyAnchor(footprint);
        academyAnchor = anchor;
      } else if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
        anchor = preferred;
      } else {
        // 可移动建筑：独占岸位空位，保证放大后锚点间距。
        anchor = _allocateExclusiveSlot(
          preferred: preferred,
          config: config,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
          usedSlotIndexes: usedSlotIndexes,
        );
      }

      placed.add(PlacedFootprint(
        anchor: anchor,
        footprint: footprint,
        buildingId: config.id,
      ));
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

  /// 独占分配岸位：严格一栋一槽，再按 preferred/区域挑最近可用槽。
  Offset _allocateExclusiveSlot({
    required Offset preferred,
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
    required Set<int> usedSlotIndexes,
  }) {
    final order = List<int>.generate(_packingSlots.length, (i) => i)
      ..sort((a, b) {
        final da = (_packingSlots[a] - preferred).distanceSquared;
        final db = (_packingSlots[b] - preferred).distanceSquared;
        return da.compareTo(db);
      });

    // 第一轮：未占用 + 区域/视觉间距都合法。
    for (final idx in order) {
      if (usedSlotIndexes.contains(idx)) continue;
      final slot = _packingSlots[idx];
      if (!_isSlotAcceptable(
        slot: slot,
        config: config,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        continue;
      }
      usedSlotIndexes.add(idx);
      return slot;
    }

    // 第二轮：未占用 + 区域合法 + 脚点/岛缘安全。
    for (final idx in order) {
      if (usedSlotIndexes.contains(idx)) continue;
      final slot = _packingSlots[idx];
      if (!_isSlotPhysicallySafe(
        slot: slot,
        footprint: footprint,
        buildingId: config.id,
      )) {
        continue;
      }
      if (!IslandBuildingLayout.isZoneValidForBuilding(
        config: config,
        anchor: slot,
        footprint: footprint,
        academyAnchor: academyAnchor,
      )) {
        continue;
      }
      if (_hasVisualCollision(
        slot,
        footprint,
        placed,
        buildingId: config.id,
      )) {
        continue;
      }
      usedSlotIndexes.add(idx);
      return slot;
    }

    // 第三轮：未占用 + 物理安全（仍禁止岛外/主角脚点重叠）。
    for (final idx in order) {
      if (usedSlotIndexes.contains(idx)) continue;
      final slot = _packingSlots[idx];
      if (!_isSlotPhysicallySafe(
        slot: slot,
        footprint: footprint,
        buildingId: config.id,
      )) {
        continue;
      }
      usedSlotIndexes.add(idx);
      return slot;
    }

    // 超过预置槽：在侧岸网格搜索仍合法的空位。
    for (var y = 0.42; y <= 0.55; y += 0.03) {
      for (final x in [0.26, 0.30, 0.34, 0.66, 0.70, 0.74]) {
        final candidate = Offset(x, y);
        if (!_isSlotAcceptable(
          slot: candidate,
          config: config,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          continue;
        }
        usedSlotIndexes.add(1000 + usedSlotIndexes.length);
        return candidate;
      }
    }
    // 最后回退：仍保证与已放置建筑的视觉间距。
    for (var y = 0.42; y <= 0.56; y += 0.02) {
      for (var x = 0.24; x <= 0.76; x += 0.02) {
        final candidate = Offset(x, y);
        if (!_isSlotPhysicallySafe(
          slot: candidate,
          footprint: footprint,
          buildingId: config.id,
        )) {
          continue;
        }
        if (_hasVisualCollision(
          candidate,
          footprint,
          placed,
          buildingId: config.id,
        )) {
          continue;
        }
        usedSlotIndexes.add(2000 + usedSlotIndexes.length);
        return candidate;
      }
    }
    usedSlotIndexes.add(3000 + usedSlotIndexes.length);
    return preferred;
  }

  bool _isSlotPhysicallySafe({
    required Offset slot,
    required Offset footprint,
    required String buildingId,
  }) {
    if (IslandBuildingLayout.footPadRect(slot, footprint)
        .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
      return false;
    }
    // 放大 + 纵深后的贴地主体仍须落在岛面内（栈桥除外）。
    return BuildingFootprint.isVisuallyOnGrowthIsland(
      slot,
      footprint,
      buildingId: buildingId,
      inset: 0.74,
    );
  }

  bool _isSlotAcceptable({
    required Offset slot,
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (!_isSlotPhysicallySafe(
      slot: slot,
      footprint: footprint,
      buildingId: config.id,
    )) {
      return false;
    }
    if (!IslandBuildingLayout.isZoneValidForBuilding(
      config: config,
      anchor: slot,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (_hasVisualCollision(
      slot,
      footprint,
      placed,
      buildingId: config.id,
    )) {
      return false;
    }
    return true;
  }

  Offset _resolveAcademyAnchor(Offset footprint) {
    // 相对旧版下移约半个图片高度，落在岛面中后景；放大后主体仍须在岛内。
    for (var y = 0.34; y <= 0.42; y += 0.008) {
      final candidate = Offset(0.50, y);
      if (BuildingFootprint.isVisuallyOnGrowthIsland(
        candidate,
        footprint,
        buildingId: 'growth_academy',
      )) {
        return candidate;
      }
    }
    return MainIslandPlacementZones.academyDefaultAnchor;
  }

  String _upgradeKey(growth.BuildingConfig config) {
    if (config.type == 'house') return 'growth_house';
    if (config.type == 'lighthouse' || config.type == 'lighthouse_base') {
      return 'lighthouse';
    }
    return config.id;
  }

  Offset _finalizeAnchor({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    final candidates = <Offset>[
      IslandBuildingLayout.safeFallbackAnchor(config),
      IslandPlacement.clampToGrowthIsland(config.position, inset: 0.86),
      if (config.type == 'observatory') const Offset(0.58, 0.44),
      if (config.type == 'house') const Offset(0.24, 0.54),
      const Offset(0.74, 0.54),
      const Offset(0.26, 0.56),
      const Offset(0.74, 0.56),
      const Offset(0.28, 0.52),
      const Offset(0.72, 0.52),
    ];
    if (_isResolvedPlacementValid(
      config: config,
      anchor: anchor,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return anchor;
    }
    for (final candidate in candidates) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    for (var y = 0.24; y <= 0.68; y += 0.008) {
      for (var x = 0.22; x <= 0.78; x += 0.008) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isResolvedPlacementValid(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    final fallback = IslandBuildingLayout.safeFallbackAnchor(config);
    if (_isResolvedPlacementValid(
      config: config,
      anchor: fallback,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return fallback;
    }

    for (var y = 0.24; y <= 0.68; y += 0.006) {
      for (var x = 0.22; x <= 0.78; x += 0.006) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isResolvedPlacementValid(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }

    final hardened = _findBestFallbackAnchor(
      config: config,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (hardened != null) return hardened;

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    return hardened ??
        _pickPackingSlot(
          config: config,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        ) ??
        IslandBuildingLayout.safeFallbackAnchor(config);
  }

  static const _emergencyAnchors = <Offset>[
    Offset(0.22, 0.54),
    Offset(0.78, 0.54),
    Offset(0.20, 0.56),
    Offset(0.80, 0.56),
    Offset(0.24, 0.52),
    Offset(0.76, 0.52),
    Offset(0.26, 0.50),
    Offset(0.74, 0.50),
    Offset(0.28, 0.48),
    Offset(0.72, 0.48),
    Offset(0.30, 0.46),
    Offset(0.70, 0.46),
  ];

  Offset _nudgeOutOfProtagonist({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
    required bool preferLeft,
  }) {
    final xRanges = preferLeft
        ? const [(0.16, 0.30), (0.70, 0.84)]
        : const [(0.70, 0.84), (0.16, 0.30)];
    for (final range in xRanges) {
      // 避开左右广场带（约 y 0.56–0.68）。
      for (var y = 0.48; y <= 0.55; y += 0.008) {
        for (var x = range.$1; x <= range.$2; x += 0.008) {
          final candidate =
              IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
          if (!_isResolvedPlacementValid(
            config: config,
            anchor: candidate,
            footprint: footprint,
            placed: placed,
            academyAnchor: academyAnchor,
          )) {
            continue;
          }
          if (IslandBuildingLayout.footPadRect(candidate, footprint)
              .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
            continue;
          }
          return candidate;
        }
      }
    }
    return IslandBuildingLayout.safeFallbackAnchor(config);
  }

  Offset? _findBestFallbackAnchor({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    Offset? best;
    var bestDistance = double.infinity;
    final preferred = IslandBuildingLayout.safeFallbackAnchor(config);
    for (var y = 0.24; y <= 0.68; y += 0.004) {
      for (var x = 0.22; x <= 0.78; x += 0.004) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (!_isResolvedPlacementValid(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          continue;
        }
        final dist = (candidate - preferred).distanceSquared;
        if (dist < bestDistance) {
          bestDistance = dist;
          best = candidate;
        }
      }
    }
    return best;
  }

  Offset _coerceValidAnchor({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (_isResolvedPlacementValid(
      config: config,
      anchor: anchor,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    )) {
      return anchor;
    }

    final best = _findBestFallbackAnchor(
      config: config,
      footprint: footprint,
      placed: placed,
      academyAnchor: academyAnchor,
    );
    if (best != null) return best;

    for (final candidate in _emergencyAnchors) {
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }

    // 仍找不到时：走预置空位 / 穷举，保证不与已放置视觉盒重叠。
    return _pickPackingSlot(
          config: config,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        ) ??
        _desperateFreeAnchor(
          config: config,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        ) ??
        IslandBuildingLayout.safeFallbackAnchor(config);
  }

  Offset? _desperateFreeAnchor({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    final seed = config.id.hashCode.abs();
    for (var i = 0; i < 240; i++) {
      final x = 0.16 + ((seed + i * 37) % 69) / 100.0;
      final y = 0.46 + ((seed + i * 53) % 13) / 100.0;
      final candidate =
          IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.82);
      if (_isCollisionFreePlacement(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }
    return null;
  }

  /// 14 个岸位（扫描自 tent/地标合法带），最小间距 ≥0.056。
  /// 外层供地标（学院 clearance≥0.22）；侧岸供帐篷等占地较大的普通建筑。
  static const _packingSlots = <Offset>[
    Offset(0.28, 0.42),
    Offset(0.36, 0.42),
    Offset(0.62, 0.42),
    Offset(0.72, 0.42),
    Offset(0.32, 0.48),
    Offset(0.42, 0.46),
    Offset(0.56, 0.47),
    Offset(0.64, 0.48),
    Offset(0.26, 0.51),
    Offset(0.30, 0.55),
    Offset(0.72, 0.52),
    Offset(0.76, 0.56),
    Offset(0.38, 0.52),
    Offset(0.60, 0.53),
  ];

  Offset? _pickPackingSlot({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    for (final slot in _packingSlots) {
      final candidate =
          IslandPlacement.clampToGrowthIsland(slot, inset: 0.84);
      if (_isResolvedPlacementValid(
        config: config,
        anchor: candidate,
        footprint: footprint,
        placed: placed,
        academyAnchor: academyAnchor,
      )) {
        return candidate;
      }
    }
    for (var y = 0.46; y <= 0.58; y += 0.01) {
      for (var x = 0.16; x <= 0.84; x += 0.01) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.84);
        if (_isResolvedPlacementValid(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }
    // 放宽岛缘完整占地：只要求锚点在岛上 + 视觉盒不重叠。
    for (var y = 0.46; y <= 0.58; y += 0.008) {
      for (var x = 0.16; x <= 0.84; x += 0.008) {
        final candidate =
            IslandPlacement.clampToGrowthIsland(Offset(x, y), inset: 0.82);
        if (_isCollisionFreePlacement(
          config: config,
          anchor: candidate,
          footprint: footprint,
          placed: placed,
          academyAnchor: academyAnchor,
        )) {
          return candidate;
        }
      }
    }
    return null;
  }

  bool _isCollisionFreePlacement({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (!IslandPlacement.isOnGrowthIsland(anchor, inset: 0.80)) {
      return false;
    }
    if (!IslandBuildingLayout.isZoneValidForBuilding(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (config.id != 'harbor_pier' &&
        config.id != 'starter_stone' &&
        IslandBuildingLayout.footPadRect(anchor, footprint)
            .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
      return false;
    }
    return !_hasVisualCollision(
      anchor,
      footprint,
      placed,
      buildingId: config.id,
    );
  }

  bool _hasVisualCollision(
    Offset anchor,
    Offset footprint,
    List<PlacedFootprint> placed, {
    required String buildingId,
  }) {
    return IslandBuildingLayout.collisionOverlapsPlaced(
      anchor,
      footprint,
      placed,
      buildingId: buildingId,
    );
  }

  /// 最后手段：忽略部分区域约束，只保证视觉间距且锚点在岛上。
  Offset? _forceNoVisualOverlap({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
  }) {
    for (var y = 0.44; y <= 0.58; y += 0.02) {
      for (var x in const [
        0.18, 0.22, 0.26, 0.30, 0.34,
        0.66, 0.70, 0.74, 0.78, 0.82,
      ]) {
        final candidate = Offset(x, y);
        if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.78)) {
          continue;
        }
        if (config.id != 'starter_stone' &&
            IslandBuildingLayout.footPadRect(candidate, footprint)
                .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
          continue;
        }
        if (_hasVisualCollision(
          candidate,
          footprint,
          placed,
          buildingId: config.id,
        )) {
          continue;
        }
        return candidate;
      }
    }
    return null;
  }

  /// 保底散点：按放置序号左右岸交替，步长大于视觉分离半径。
  Offset _uniqueSpreadAnchor({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    required int index,
  }) {
    return _guaranteedSeparatedAnchor(
      config: config,
      footprint: footprint,
      placed: placed,
      index: index,
    );
  }

  /// 保证与已放置建筑满足视觉间距的锚点（可放宽区域约束）。
  Offset _guaranteedSeparatedAnchor({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    required int index,
  }) {
    bool usable(Offset candidate) {
      if (!IslandPlacement.isOnGrowthIsland(candidate, inset: 0.72)) {
        return false;
      }
      // 中带留给学院与主角，建筑只落左右岸。
      if (candidate.dx > 0.36 && candidate.dx < 0.64) {
        return false;
      }
      if (_hasVisualCollision(
        candidate,
        footprint,
        placed,
        buildingId: config.id,
      )) {
        return false;
      }
      return true;
    }

    for (var step = 0; step < 96; step++) {
      final idx = index * 2 + step;
      final left = idx.isEven;
      final x = left
          ? 0.16 + ((idx ~/ 2) % 5) * 0.05
          : 0.84 - ((idx ~/ 2) % 5) * 0.05;
      final y = 0.46 + ((idx ~/ 10) % 4) * 0.025;
      final candidate = Offset(x, y.clamp(0.46, 0.56));
      if (usable(candidate)) return candidate;
    }
    for (var y = 0.46; y <= 0.56; y += 0.015) {
      for (var x = 0.14; x <= 0.86; x += 0.015) {
        final candidate = Offset(x, y);
        if (usable(candidate)) return candidate;
      }
    }
    // 最后：在岸带上选间距最大且仍满足视觉分离的点。
    Offset? best;
    var bestScore = -1.0;
    for (var y = 0.46; y <= 0.56; y += 0.02) {
      for (final x in const [0.16, 0.22, 0.28, 0.34, 0.66, 0.72, 0.78, 0.84]) {
        final candidate = Offset(x, y);
        if (!usable(candidate)) continue;
        var minD = double.infinity;
        for (final p in placed) {
          minD = math.min(minD, (p.anchor - candidate).distance);
        }
        if (minD > bestScore) {
          bestScore = minD;
          best = candidate;
        }
      }
    }
    return best ??
        (index.isEven ? const Offset(0.20, 0.52) : const Offset(0.80, 0.52));
  }

  bool _isResolvedPlacementValid({
    required growth.BuildingConfig config,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    if (!IslandBuildingLayout.isZoneValidForBuilding(
      config: config,
      anchor: anchor,
      footprint: footprint,
      academyAnchor: academyAnchor,
    )) {
      return false;
    }
    if (IslandBuildingLayout.collisionOverlapsPlaced(
      anchor,
      footprint,
      placed,
      buildingId: config.id,
    )) {
      return false;
    }
    if (!BuildingFootprint.isVisuallyOnGrowthIsland(
      anchor,
      footprint,
      buildingId: config.id,
    )) {
      return false;
    }
    if (config.id != 'harbor_pier' && config.id != 'starter_stone') {
      // 只用脚垫判主角禁区，避免高大视觉盒把建筑推离合法岸带。
      if (IslandBuildingLayout.footPadRect(anchor, footprint)
          .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
        return false;
      }
    }
    return true;
  }
}
