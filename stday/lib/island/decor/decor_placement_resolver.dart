import 'dart:math' as math;
import 'dart:ui';

import '../placement/island_placement.dart';
import 'decor_config.dart';

/// 装饰落点：避开主角占位与已占用区域，优先落在主角身后。
class DecorPlacementResolver {
  const DecorPlacementResolver();

  /// 主角脚点（归一化）；与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = Offset(0.5, 0.625);

  /// 主角占位区：装饰 occupancy 与此区域重叠则需重定位。
  static Rect get protagonistExclusionRect => Rect.fromCenter(
        center: Offset(protagonistFoot.dx, protagonistFoot.dy - 0.055),
        width: 0.24,
        height: 0.22,
      );

  /// 测试与旧逻辑兼容：装饰不应落在主角身后占位区。
  static Rect get protagonistRearZone => protagonistExclusionRect;

  /// 装饰之间的最小间距（归一化）。
  static const decorGap = 0.014;

  static const _decorGap = decorGap;

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
    Offset(0.18, 0.58),
    Offset(0.82, 0.58),
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

  Map<String, Offset> resolve(List<DecorConfig> configs) {
    final positions = <String, Offset>{};
    final occupied = <Rect>[];

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

      var candidate = _resolveGroundPosition(config, occupied);
      candidate = IslandPlacement.clampToGrowthIsland(candidate, inset: 0.72);
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
  }) {
    if (_isSkyDecor(config)) {
      return Offset(config.x, config.y);
    }
    final rng = math.Random(randomSeed);
    final defaultPos = Offset(config.x, config.y);
    if (!_conflictsWithProtagonist(defaultPos, config) &&
        !_overlapsOccupied(defaultPos, config, occupied)) {
      return defaultPos;
    }

    final slots = [..._openSlots]..shuffle(rng);
    for (final slot in slots) {
      if (!IslandPlacement.isOnGrowthIsland(slot, inset: 0.72)) continue;
      if (_conflictsWithProtagonist(slot, config)) continue;
      if (!_overlapsOccupied(slot, config, occupied)) {
        return IslandPlacement.clampToGrowthIsland(slot, inset: 0.72);
      }
    }

    final probed = _probeNonOverlapping(config, occupied, seed: randomSeed);
    if (probed != null) return probed;

    return IslandPlacement.clampToGrowthIsland(defaultPos, inset: 0.72);
  }

  Offset _resolveGroundPosition(DecorConfig config, List<Rect> occupied) {
    final defaultPos = Offset(config.x, config.y);
    if (!_conflictsWithProtagonist(defaultPos, config) &&
        !_overlapsOccupied(defaultPos, config, occupied)) {
      return defaultPos;
    }

    final fromSlots = _findOpenSlot(config, occupied) ??
        _findOpenSlot(config, occupied, forceRear: true) ??
        _rearFallback(config, occupied);
    if (fromSlots != null) return fromSlots;

    final probed = _probeNonOverlapping(config, occupied);
    if (probed != null) return probed;

    return defaultPos;
  }

  bool isSkyDecor(DecorConfig config) {
    return _isSkyDecor(config);
  }

  Rect paddedOccupancyFor(DecorConfig config, Offset p) {
    return _paddedOccupancyRect(config, p);
  }

  bool _isSkyDecor(DecorConfig config) {
    return config.category == DecorCategory.cloud ||
        config.category == DecorCategory.bird ||
        config.category == DecorCategory.butterfly ||
        config.category == DecorCategory.firefly;
  }

  bool _conflictsWithProtagonist(Offset p, DecorConfig config) {
    return _paddedOccupancyRect(config, p).overlaps(protagonistExclusionRect);
  }

  bool _overlapsOccupied(
    Offset p,
    DecorConfig config,
    List<Rect> occupied,
  ) {
    final rect = _paddedOccupancyRect(config, p);
    return occupied.any((o) => o.overlaps(rect));
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
  }) {
    final rng = math.Random(config.id.hashCode);
    final slots = [..._openSlots];
    if (forceRear) {
      slots.sort((a, b) => a.dy.compareTo(b.dy));
    } else {
      slots.shuffle(rng);
    }
    for (final slot in slots) {
      if (forceRear && slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (!IslandPlacement.isOnGrowthIsland(slot, inset: 0.72)) continue;
      if (_conflictsWithProtagonist(slot, config)) continue;
      if (!_overlapsOccupied(slot, config, occupied)) return slot;
    }
    return null;
  }

  Offset? _rearFallback(DecorConfig config, List<Rect> occupied) {
    for (final slot in _openSlots) {
      if (slot.dy >= protagonistFoot.dy - 0.04) continue;
      if (!IslandPlacement.isOnGrowthIsland(slot, inset: 0.72)) continue;
      if (_conflictsWithProtagonist(slot, config)) continue;
      if (!_overlapsOccupied(slot, config, occupied)) return slot;
    }
    return null;
  }

  Offset? _probeNonOverlapping(DecorConfig config, List<Rect> occupied,
      {int? seed}) {
    final rng = math.Random(seed ?? config.id.hashCode + 17);
    for (var ring = 0; ring < 8; ring++) {
      for (var i = 0; i < 16; i++) {
        final angle = (math.pi * 2 / 16) * i + ring * 0.18;
        final dist = 0.35 + ring * 0.06 + rng.nextDouble() * 0.04;
        final probe = IslandPlacement.clampToGrowthIsland(
          Offset(
            protagonistFoot.dx + math.cos(angle) * 0.24 * dist,
            protagonistFoot.dy - 0.08 - ring * 0.018 - rng.nextDouble() * 0.05,
          ),
          inset: 0.68,
        );
        if (_conflictsWithProtagonist(probe, config)) continue;
        if (!_overlapsOccupied(probe, config, occupied)) return probe;
      }
    }
    return null;
  }
}
