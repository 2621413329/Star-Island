import 'package:flutter/material.dart';

/// Growth Island 2.0 固定视觉基准：岛型与地表色不随心情变化。
class IslandVisualConfig {
  IslandVisualConfig._();

  static const fixedShapeKey = 'growth_world';
  static const fixedBiome = 'growth_world';
  static const centerLandmarkId = 'growth_tree';

  static const grass = Color(0xFF7EC87A);
  static const sand = Color(0xFFE8E0D4);
  static const sea = Color(0xFF5BB5D5);
  static const accent = Color(0xFFE8B86D);
  static const flower = Color(0xFFF8BBD0);

  static const _prosperityThresholds = [
    (minLevel: 1, tier: 0),
    (minLevel: 2, tier: 1),
    (minLevel: 3, tier: 2),
    (minLevel: 5, tier: 3),
    (minLevel: 7, tier: 4),
    (minLevel: 10, tier: 5),
  ];

  /// 成长繁荣度档位（纵向成长，非建筑解锁）。
  static int prosperityTierFromLevel(int level) {
    return _prosperityThresholds
        .lastWhere(
          (threshold) => level >= threshold.minLevel,
          orElse: () => _prosperityThresholds.first,
        )
        .tier;
  }

  static String prosperityLabel(int tier) => switch (tier) {
        0 => '荒芜小岛',
        1 => '萌芽之岛',
        2 => '绿意渐生',
        3 => '小径连通',
        4 => '桥梁架起',
        _ => '成长世界',
      };
}
