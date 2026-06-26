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

  static const _openSlots = <Offset>[
    // 身后远端（画面上方，dy 较小）
    Offset(0.30, 0.46),
    Offset(0.38, 0.48),
    Offset(0.46, 0.47),
    Offset(0.54, 0.47),
    Offset(0.62, 0.48),
    Offset(0.70, 0.46),
    Offset(0.34, 0.51),
    Offset(0.66, 0.51),
    // 左右前方（与脚点保持距离）
    Offset(0.22, 0.58),
    Offset(0.78, 0.58),
    Offset(0.26, 0.64),
    Offset(0.74, 0.64),
    Offset(0.30, 0.60),
    Offset(0.70, 0.60),
    Offset(0.18, 0.60),
    Offset(0.82, 0.60),
    Offset(0.34, 0.66),
    Offset(0.66, 0.66),
    Offset(0.40, 0.62),
    Offset(0.60, 0.62),
    Offset(0.28, 0.66),
    Offset(0.72, 0.66),
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

      var candidate = Offset(config.x, config.y);
      if (_conflictsWithProtagonist(candidate, config) ||
          _overlapsOccupied(candidate, config, occupied)) {
        candidate = _findOpenSlot(config, occupied) ?? candidate;
      }

      if (_conflictsWithProtagonist(candidate, config)) {
        candidate = _findOpenSlot(config, occupied, forceRear: true) ??
            _rearFallback(config, occupied) ??
            candidate;
      }

      candidate = IslandPlacement.clampToGrowthIsland(candidate, inset: 0.72);
      positions[config.id] = candidate;
      occupied.add(_occupancyRect(config, candidate));
    }

    return positions;
  }

  bool _isSkyDecor(DecorConfig config) {
    return config.category == DecorCategory.cloud ||
        config.category == DecorCategory.bird ||
        config.category == DecorCategory.butterfly ||
        config.category == DecorCategory.firefly;
  }

  bool _conflictsWithProtagonist(Offset p, DecorConfig config) {
    return _occupancyRect(config, p).overlaps(protagonistExclusionRect);
  }

  bool _overlapsOccupied(
    Offset p,
    DecorConfig config,
    List<Rect> occupied,
  ) {
    final rect = _occupancyRect(config, p);
    return occupied.any((o) => o.overlaps(rect));
  }

  Rect _occupancyRect(DecorConfig config, Offset p) {
    final w = switch (config.category) {
      DecorCategory.tree => 0.10,
      DecorCategory.bush => 0.08,
      DecorCategory.pond => 0.12,
      _ => 0.06,
    };
    final h = w * 1.1;
    return Rect.fromCenter(
      center: Offset(p.dx, p.dy - h * 0.35),
      width: w,
      height: h,
    );
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
    for (var i = 0; i < 32; i++) {
      final angle = rng.nextDouble() * math.pi;
      final dist = 0.45 + rng.nextDouble() * 0.55;
      final probe = IslandPlacement.clampToGrowthIsland(
        Offset(
          protagonistFoot.dx + math.cos(angle) * 0.22 * dist,
          protagonistFoot.dy - 0.06 - rng.nextDouble() * 0.14,
        ),
        inset: 0.68,
      );
      if (_conflictsWithProtagonist(probe, config)) continue;
      if (!_overlapsOccupied(probe, config, occupied)) return probe;
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
}
