import 'dart:math' as math;
import 'dart:ui';

import '../placement/island_placement.dart';
import 'decor_config.dart';

/// 装饰落点：避开主角脚点与已占用区域，身后区域可放置解锁建筑/装饰。
class DecorPlacementResolver {
  const DecorPlacementResolver();

  /// 主角脚点（归一化）；与 [ProtagonistBehavior.defaultBase] 对齐。
  static const protagonistFoot = Offset(0.5, 0.625);

  /// 仅排除脚边极小范围，身后区域允许放置解锁内容。
  static const _footClearance = 0.038;

  static const _openSlots = <Offset>[
    // 身后（画面上方）
    Offset(0.38, 0.52),
    Offset(0.50, 0.50),
    Offset(0.62, 0.52),
    Offset(0.44, 0.54),
    Offset(0.56, 0.54),
    // 左右前方
    Offset(0.26, 0.64),
    Offset(0.74, 0.64),
    Offset(0.30, 0.60),
    Offset(0.70, 0.60),
    Offset(0.22, 0.58),
    Offset(0.78, 0.58),
    Offset(0.34, 0.66),
    Offset(0.66, 0.66),
    Offset(0.40, 0.62),
    Offset(0.60, 0.62),
    Offset(0.28, 0.66),
    Offset(0.72, 0.66),
    Offset(0.18, 0.60),
    Offset(0.82, 0.60),
    Offset(0.36, 0.58),
    Offset(0.64, 0.58),
  ];

  Map<String, Offset> resolve(List<DecorConfig> configs) {
    final positions = <String, Offset>{};
    final occupied = <Rect>[];

    final sorted = [...configs]..sort((a, b) {
        final aConflict = _conflictsWithProtagonist(Offset(a.x, a.y));
        final bConflict = _conflictsWithProtagonist(Offset(b.x, b.y));
        if (aConflict != bConflict) return aConflict ? -1 : 1;
        return a.unlockLevel.compareTo(b.unlockLevel);
      });

    for (final config in sorted) {
      if (_isSkyDecor(config)) {
        positions[config.id] = Offset(config.x, config.y);
        continue;
      }

      var candidate = Offset(config.x, config.y);
      if (_conflictsWithProtagonist(candidate) ||
          _overlapsOccupied(candidate, config, occupied)) {
        candidate = _findOpenSlot(config, occupied) ?? candidate;
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

  bool _conflictsWithProtagonist(Offset p) {
    return (p - protagonistFoot).distance < _footClearance;
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

  Offset? _findOpenSlot(DecorConfig config, List<Rect> occupied) {
    final rng = math.Random(config.id.hashCode);
    final slots = [..._openSlots]..shuffle(rng);
    for (final slot in slots) {
      if (!IslandPlacement.isOnGrowthIsland(slot, inset: 0.72)) continue;
      if (_conflictsWithProtagonist(slot)) continue;
      if (!_overlapsOccupied(slot, config, occupied)) return slot;
    }
    for (var i = 0; i < 24; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 0.55 + rng.nextDouble() * 0.35;
      final probe = IslandPlacement.clampToGrowthIsland(
        Offset(
          protagonistFoot.dx + math.cos(angle) * 0.18 * dist,
          protagonistFoot.dy + math.sin(angle) * 0.06 * dist + 0.02,
        ),
        inset: 0.68,
      );
      if (_conflictsWithProtagonist(probe)) continue;
      if (!_overlapsOccupied(probe, config, occupied)) return probe;
    }
    return null;
  }
}
