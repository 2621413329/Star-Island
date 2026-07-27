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
  BuildingResolver();

  double _activeIslandRadius = 1.0;

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
    _activeIslandRadius = islandRadius;
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
      final baseFootprint =
          BuildingFootprint.resolve(config, islandRadius: islandRadius);
      final preferred = IslandBuildingLayout.preferredAnchor(
        config,
        islandRadius: islandRadius,
      );

      late final Offset anchor;
      var footprint = baseFootprint;
      if (config.id == 'growth_academy') {
        anchor = _resolveAcademyAnchor(footprint);
        academyAnchor = anchor;
      } else if (config.id == 'harbor_pier' || config.id == 'starter_stone') {
        anchor = preferred;
        if (config.id == 'starter_stone' &&
            !BuildingFootprint.isVisuallyOnGrowthIsland(
              anchor,
              footprint,
              buildingId: config.id,
              islandRadius: islandRadius,
            )) {
          anchor = MainIslandPlacementZones.clampBuildingAnchor(
            preferred,
            footprint,
            islandRadius: islandRadius,
          );
        }
      } else {
        // 可移动建筑：独占岸位；挤满时缩小/挪动邻居再找空位。
        final allocated = _allocateExclusiveSlot(
          preferred: preferred,
          config: config,
          footprint: baseFootprint,
          placed: placed,
          snapshots: snapshots,
          academyAnchor: academyAnchor,
          usedSlotIndexes: usedSlotIndexes,
        );
        anchor = allocated.anchor;
        footprint = allocated.footprint;
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

  static const _immovableBuildingIds = {
    'growth_academy',
    'harbor_pier',
    'starter_stone',
  };

  /// 独占分配岸位；挤满时动态缩小自身/邻居并挪动邻居腾空位。
  _AllocatedSlot _allocateExclusiveSlot({
    required Offset preferred,
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    required List<BuildingSnapshot> snapshots,
    Offset? academyAnchor,
    required Set<int> usedSlotIndexes,
  }) {
    // 先尝试原尺寸与逐步缩小自身。
    for (final scale in const [1.0, 0.92, 0.85, 0.78]) {
      final scaled = _scaledFootprint(footprint, scale);
      final found = _findFreeAnchor(
        preferred: preferred,
        config: config,
        footprint: scaled,
        placed: placed,
        academyAnchor: academyAnchor,
        usedSlotIndexes: usedSlotIndexes,
        claimSlot: true,
      );
      if (found != null) {
        return _AllocatedSlot(found, scaled);
      }
    }

    // 再挪动/缩小邻近可移动建筑，腾出空位后重试。
    final repacked = _repackNeighborsForSpace(
      preferred: preferred,
      config: config,
      footprint: footprint,
      placed: placed,
      snapshots: snapshots,
      academyAnchor: academyAnchor,
      usedSlotIndexes: usedSlotIndexes,
    );
    if (repacked != null) return repacked;

    // 最后手段：岸带保证间距散点（自身可再缩小）。
    for (final scale in const [0.78, 0.72]) {
      final scaled = _scaledFootprint(footprint, scale);
      usedSlotIndexes.add(3000 + usedSlotIndexes.length);
      final anchor = _guaranteedSeparatedAnchor(
        config: config,
        footprint: scaled,
        placed: placed,
        index: usedSlotIndexes.length,
      );
      if (!_hasVisualCollision(
            anchor,
            scaled,
            placed,
            buildingId: config.id,
          ) &&
          _isSlotPhysicallySafe(
            slot: anchor,
            footprint: scaled,
            buildingId: config.id,
          )) {
        return _AllocatedSlot(anchor, scaled);
      }
    }

    usedSlotIndexes.add(3000 + usedSlotIndexes.length);
    return _AllocatedSlot(
      _guaranteedSeparatedAnchor(
        config: config,
        footprint: footprint,
        placed: placed,
        index: usedSlotIndexes.length,
      ),
      footprint,
    );
  }

  Offset _scaledFootprint(Offset footprint, double scale) {
    if ((scale - 1.0).abs() < 0.001) return footprint;
    return Offset(footprint.dx * scale, footprint.dy * scale);
  }

  /// 在预置槽 + 网格中找无重合空位；[claimSlot] 为 true 时占用预置槽索引。
  Offset? _findFreeAnchor({
    required Offset preferred,
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
    required Set<int> usedSlotIndexes,
    required bool claimSlot,
  }) {
    final order = List<int>.generate(_packingSlots.length, (i) => i)
      ..sort((a, b) {
        final da = (_packingSlots[a] - preferred).distanceSquared;
        final db = (_packingSlots[b] - preferred).distanceSquared;
        return da.compareTo(db);
      });

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
      if (claimSlot) usedSlotIndexes.add(idx);
      return slot;
    }

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
      if (claimSlot) usedSlotIndexes.add(idx);
      return slot;
    }

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
      if (_hasVisualCollision(
        slot,
        footprint,
        placed,
        buildingId: config.id,
      )) {
        continue;
      }
      if (claimSlot) usedSlotIndexes.add(idx);
      return slot;
    }

    for (var y = 0.40; y <= 0.58; y += 0.02) {
      for (final x in const [
        0.18, 0.22, 0.26, 0.30, 0.34, 0.38,
        0.62, 0.66, 0.70, 0.74, 0.78, 0.82,
      ]) {
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
        if (claimSlot) {
          usedSlotIndexes.add(1000 + usedSlotIndexes.length);
        }
        return candidate;
      }
    }

    for (var y = 0.40; y <= 0.58; y += 0.015) {
      for (var x = 0.16; x <= 0.84; x += 0.015) {
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
        if (claimSlot) {
          usedSlotIndexes.add(2000 + usedSlotIndexes.length);
        }
        return candidate;
      }
    }
    return null;
  }

  /// 挤满时：缩小并挪动邻近可移动建筑，再为新建筑找空位。
  _AllocatedSlot? _repackNeighborsForSpace({
    required Offset preferred,
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    required List<BuildingSnapshot> snapshots,
    Offset? academyAnchor,
    required Set<int> usedSlotIndexes,
  }) {
    final neighborIndexes = <int>[
      for (var i = 0; i < placed.length; i++)
        if (!_immovableBuildingIds.contains(placed[i].buildingId)) i,
    ]..sort((a, b) {
        final da = (placed[a].anchor - preferred).distanceSquared;
        final db = (placed[b].anchor - preferred).distanceSquared;
        return da.compareTo(db);
      });
    if (neighborIndexes.isEmpty) return null;

    final nearest = neighborIndexes.take(6).toList(growable: false);
    const selfScales = [1.0, 0.90, 0.82, 0.75];
    const neighborScales = [1.0, 0.90, 0.80];
    const nudgeSteps = [0.025, 0.045, 0.065];
    const dirs = <Offset>[
      Offset(-1, 0),
      Offset(1, 0),
      Offset(0, -1),
      Offset(0, 1),
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 1),
      Offset(1, 1),
    ];

    for (final selfScale in selfScales) {
      final selfFp = _scaledFootprint(footprint, selfScale);
      for (final neighborScale in neighborScales) {
        for (final neighborIndex in nearest) {
          final original = placed[neighborIndex];
          final shrunk = _scaledFootprint(original.footprint, neighborScale);

          // 优先沿「远离 preferred」方向挪动，给新建筑让路。
          final away = original.anchor - preferred;
          final primaryDir = away.distanceSquared < 1e-8
              ? (original.anchor.dx <= 0.5
                  ? const Offset(-1, 0)
                  : const Offset(1, 0))
              : Offset(away.dx / away.distance, away.dy / away.distance);

          final tryDirs = <Offset>[primaryDir, ...dirs];
          for (final step in nudgeSteps) {
            for (final dir in tryDirs) {
              final len = dir.distance;
              if (len < 1e-8) continue;
              final candidate = IslandPlacement.clampToGrowthIsland(
                original.anchor + Offset(dir.dx / len * step, dir.dy / len * step),
                inset: 0.84,
              );

              if (!_isNeighborRelocationValid(
                buildingId: original.buildingId,
                anchor: candidate,
                footprint: shrunk,
                placed: placed,
                selfIndex: neighborIndex,
                academyAnchor: academyAnchor,
              )) {
                continue;
              }

              // 临时应用挪动/缩小。
              placed[neighborIndex] = PlacedFootprint(
                anchor: candidate,
                footprint: shrunk,
                buildingId: original.buildingId,
              );

              final found = _findFreeAnchor(
                preferred: preferred,
                config: config,
                footprint: selfFp,
                placed: placed,
                academyAnchor: academyAnchor,
                usedSlotIndexes: usedSlotIndexes,
                claimSlot: true,
              );
              if (found != null) {
                _syncSnapshotPlacement(
                  snapshots,
                  buildingId: original.buildingId,
                  anchor: candidate,
                  footprint: shrunk,
                );
                return _AllocatedSlot(found, selfFp);
              }

              // 回滚邻居。
              placed[neighborIndex] = original;
            }
          }
        }
      }
    }
    return null;
  }

  bool _isNeighborRelocationValid({
    required String buildingId,
    required Offset anchor,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    required int selfIndex,
    Offset? academyAnchor,
  }) {
    if (!_isSlotPhysicallySafe(
      slot: anchor,
      footprint: footprint,
      buildingId: buildingId,
    )) {
      return false;
    }
    final others = <PlacedFootprint>[
      for (var i = 0; i < placed.length; i++)
        if (i != selfIndex) placed[i],
    ];
    if (_hasVisualCollision(
      anchor,
      footprint,
      others,
      buildingId: buildingId,
    )) {
      return false;
    }
    if (academyAnchor != null &&
        buildingId != 'growth_academy' &&
        (anchor - academyAnchor).distance < 0.12) {
      return false;
    }
    return true;
  }

  void _syncSnapshotPlacement(
    List<BuildingSnapshot> snapshots, {
    required String buildingId,
    required Offset anchor,
    required Offset footprint,
  }) {
    final index = snapshots.indexWhere((s) => s.definitionId == buildingId);
    if (index < 0) return;
    final old = snapshots[index];
    snapshots[index] = BuildingSnapshot(
      definitionId: old.definitionId,
      level: old.level,
      anchor: anchor,
      zone: old.zone,
      type: old.type,
      size: footprint,
      sprite: old.sprite,
      animation: old.animation,
      interactionType: old.interactionType,
      playUnlockFx: old.playUnlockFx,
      displayName: old.displayName,
      unlockLevel: old.unlockLevel,
      unlockedAt: old.unlockedAt,
    );
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
    if (buildingId != 'starter_stone' && buildingId != 'harbor_pier') {
      final occupancy = IslandBuildingLayout.occupancyRect(
        slot,
        footprint,
        buildingId: buildingId,
      );
      if (MainIslandPlacementZones.buildingOverlapsLargeTreeShoreParcel(occupancy)) {
        return false;
      }
    }
    // 放大 + 纵深后的贴地主体仍须落在岛面内（栈桥除外）。
    return BuildingFootprint.isVisuallyOnGrowthIsland(
      slot,
      footprint,
      buildingId: buildingId,
      inset: 0.74,
      islandRadius: _activeIslandRadius,
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
    // 岛面中后景：按当前半径从默认锚点收缩，再在合法带内微调。
    final preferred = IslandPlacement.clampToGrowthIsland(
      IslandPlacement.scaleAnchorToRadius(
        MainIslandPlacementZones.academyDefaultAnchor,
        islandRadius: _activeIslandRadius,
      ),
      inset: 0.88,
      islandRadius: _activeIslandRadius,
    );
    final searchYs = <double>[
      preferred.dy,
      for (var y = preferred.dy; y <= preferred.dy + 0.06; y += 0.008) y,
      for (var y = preferred.dy; y >= preferred.dy - 0.04; y -= 0.008) y,
    ];
    for (final y in searchYs) {
      final candidate = IslandPlacement.clampToGrowthIsland(
        Offset(0.50, y),
        inset: 0.88,
        islandRadius: _activeIslandRadius,
      );
      if (BuildingFootprint.isVisuallyOnGrowthIsland(
        candidate,
        footprint,
        buildingId: 'growth_academy',
        islandRadius: _activeIslandRadius,
      )) {
        return candidate;
      }
    }
    return preferred;
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
      IslandBuildingLayout.safeFallbackAnchor(
        config,
        islandRadius: _activeIslandRadius,
      ),
      IslandPlacement.clampToGrowthIsland(
        config.position,
        inset: 0.86,
        islandRadius: _activeIslandRadius,
      ),
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
        final candidate = IslandPlacement.clampToGrowthIsland(
          IslandPlacement.scaleAnchorToRadius(
            Offset(x, y),
            islandRadius: _activeIslandRadius,
          ),
          inset: 0.84,
          islandRadius: _activeIslandRadius,
        );
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

    final fallback = IslandBuildingLayout.safeFallbackAnchor(
      config,
      islandRadius: _activeIslandRadius,
    );
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
        final candidate = IslandPlacement.clampToGrowthIsland(
          IslandPlacement.scaleAnchorToRadius(
            Offset(x, y),
            islandRadius: _activeIslandRadius,
          ),
          inset: 0.84,
          islandRadius: _activeIslandRadius,
        );
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
      final candidate = IslandPlacement.clampToGrowthIsland(
        Offset(x, y),
        inset: 0.82,
        islandRadius: _activeIslandRadius,
      );
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

  /// 16 个岸位：左右外扩、前后拉开，相邻间距 ≥ ≈0.078。
  /// 外层供地标；侧岸供帐篷等占地较大的普通建筑。
  static const _packingSlots = <Offset>[
    Offset(0.22, 0.40),
    Offset(0.34, 0.40),
    Offset(0.66, 0.40),
    Offset(0.78, 0.40),
    Offset(0.18, 0.48),
    Offset(0.30, 0.46),
    Offset(0.70, 0.46),
    Offset(0.82, 0.48),
    Offset(0.24, 0.54),
    Offset(0.36, 0.52),
    Offset(0.64, 0.52),
    Offset(0.76, 0.54),
    Offset(0.20, 0.58),
    Offset(0.80, 0.58),
    Offset(0.40, 0.48),
    Offset(0.60, 0.48),
  ];

  Offset? _pickPackingSlot({
    required growth.BuildingConfig config,
    required Offset footprint,
    required List<PlacedFootprint> placed,
    Offset? academyAnchor,
  }) {
    for (final slot in _packingSlots) {
      final candidate = IslandPlacement.clampToGrowthIsland(
        IslandPlacement.scaleAnchorToRadius(
          slot,
          islandRadius: _activeIslandRadius,
        ),
        inset: 0.84,
        islandRadius: _activeIslandRadius,
      );
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
        final candidate = IslandPlacement.clampToGrowthIsland(
          IslandPlacement.scaleAnchorToRadius(
            Offset(x, y),
            islandRadius: _activeIslandRadius,
          ),
          inset: 0.84,
          islandRadius: _activeIslandRadius,
        );
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
        final candidate = IslandPlacement.clampToGrowthIsland(
          IslandPlacement.scaleAnchorToRadius(
            Offset(x, y),
            islandRadius: _activeIslandRadius,
          ),
          inset: 0.82,
          islandRadius: _activeIslandRadius,
        );
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
    if (!IslandPlacement.isOnGrowthIsland(
      anchor,
      inset: 0.80,
      islandRadius: _activeIslandRadius,
    )) {
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
        if (!IslandPlacement.isOnGrowthIsland(
          candidate,
          inset: 0.78,
          islandRadius: _activeIslandRadius,
        )) {
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
    bool usable(Offset candidate, {bool allowCenter = false}) {
      if (!BuildingFootprint.isVisuallyOnGrowthIsland(
        candidate,
        footprint,
        buildingId: config.id,
        inset: 0.74,
        islandRadius: _activeIslandRadius,
      )) {
        return false;
      }
      if (IslandBuildingLayout.footPadRect(candidate, footprint)
          .overlaps(MainIslandPlacementZones.protagonistExclusion)) {
        return false;
      }
      // 中带留给学院与主角；穷尽时才短暂开放侧前岸，不开岛心。
      if (!allowCenter && candidate.dx > 0.36 && candidate.dx < 0.64) {
        return false;
      }
      if (allowCenter &&
          candidate.dx > 0.40 &&
          candidate.dx < 0.60 &&
          candidate.dy < 0.52) {
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

    for (var step = 0; step < 120; step++) {
      final idx = index * 2 + step;
      final left = idx.isEven;
      final x = left
          ? 0.14 + ((idx ~/ 2) % 6) * 0.045
          : 0.86 - ((idx ~/ 2) % 6) * 0.045;
      final y = 0.40 + ((idx ~/ 12) % 6) * 0.03;
      final candidate = IslandPlacement.clampToGrowthIsland(
        IslandPlacement.scaleAnchorToRadius(
          Offset(x, y.clamp(0.40, 0.58)),
          islandRadius: _activeIslandRadius,
        ),
        inset: 0.82,
        islandRadius: _activeIslandRadius,
      );
      if (usable(candidate)) return candidate;
    }
    for (var y = 0.40; y <= 0.58; y += 0.012) {
      for (var x = 0.14; x <= 0.86; x += 0.012) {
        final candidate = IslandPlacement.clampToGrowthIsland(
          IslandPlacement.scaleAnchorToRadius(
            Offset(x, y),
            islandRadius: _activeIslandRadius,
          ),
          inset: 0.82,
          islandRadius: _activeIslandRadius,
        );
        if (usable(candidate)) return candidate;
      }
    }
    // 仍找不到：短暂开放中带，选与已放置建筑间距最大的合法点。
    Offset? best;
    var bestScore = -1.0;
    for (final allowCenter in const [false, true]) {
      for (var y = 0.38; y <= 0.60; y += 0.012) {
        for (var x = 0.14; x <= 0.86; x += 0.012) {
          final candidate = Offset(x, y);
          if (!usable(candidate, allowCenter: allowCenter)) continue;
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
      if (best != null) return best;
    }
    // 绝对兜底：仅左右岸最大化最小间距（不进主角区/岛心）。
    for (var y = 0.40; y <= 0.58; y += 0.015) {
      for (final x in const [
        0.16, 0.20, 0.24, 0.28, 0.32, 0.36,
        0.64, 0.68, 0.72, 0.76, 0.80, 0.84,
      ]) {
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
        IslandPlacement.clampToGrowthIsland(
          index.isEven ? const Offset(0.18, 0.50) : const Offset(0.82, 0.50),
          inset: 0.80,
          islandRadius: _activeIslandRadius,
        );
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
      islandRadius: _activeIslandRadius,
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

class _AllocatedSlot {
  const _AllocatedSlot(this.anchor, this.footprint);

  final Offset anchor;
  final Offset footprint;
}
