import 'dart:ui';

import '../config/growth_island_config_models.dart';
import '../config/island_visual_config.dart';

/// 建筑在岛面上的归一化占地（宽 × 高），随岛屿半径等比缩放。
///
/// [Offset.dx] = 宽度系数，[Offset.dy] = 高度系数（渲染时 × 280 为屏幕高度）。
/// 高度层级：灯塔 > 钟塔 > 天文台 > 学院 > 小屋 > 小型设施 > 石头。
class BuildingFootprint {
  BuildingFootprint._();

  static const _baseRadius = IslandVisualConfig.baseIslandRadius;
  static const _globalDisplayScale = 0.86;
  static const _academyDisplayScale = 0.90;

  static Offset resolve(BuildingConfig config, {required double islandRadius}) {
    final base = _baseFootprint(config);
    final islandScale = (islandRadius / _baseRadius).clamp(0.85, 1.35);
    final displayScale = config.id == 'growth_academy'
        ? _academyDisplayScale
        : _globalDisplayScale;
    return Offset(
      base.dx * islandScale * displayScale,
      base.dy * islandScale * displayScale,
    );
  }

  static Offset _baseFootprint(BuildingConfig config) {
    return switch (config.id) {
      'lighthouse' => const Offset(0.15, 0.46),
      'growth_clocktower' => const Offset(0.17, 0.40),
      'dream_observatory' => const Offset(0.22, 0.36),
      'growth_academy' => const Offset(0.34, 0.28),
      'lighthouse_base' => const Offset(0.18, 0.26),
      'growth_house_lv2' => const Offset(0.32, 0.28),
      'growth_house' => const Offset(0.28, 0.24),
      'library_seed' || 'memory_gallery' => const Offset(0.26, 0.26),
      'record_shed' || 'quiet_tent' => const Offset(0.24, 0.20),
      'memory_fountain' => const Offset(0.22, 0.22),
      'emotion_windchime' => const Offset(0.12, 0.24),
      'starter_stone' => const Offset(0.11, 0.11),
      'memory_mailbox' => const Offset(0.13, 0.13),
      'harbor_pier' ||
      'story_plaza' ||
      'companion_plaza' =>
        const Offset(0.32, 0.13),
      'habit_flowerbed' => const Offset(0.26, 0.11),
      _ => _footprintForType(config.type, config.upgradeLevel),
    };
  }

  static Offset _footprintForType(String type, int upgradeLevel) {
    return switch (type) {
      'lighthouse' => const Offset(0.15, 0.46),
      'lighthouse_base' => const Offset(0.18, 0.26),
      'clocktower' => const Offset(0.17, 0.40),
      'observatory' => const Offset(0.22, 0.36),
      'academy' => const Offset(0.34, 0.28),
      'house' => Offset(0.28 + upgradeLevel * 0.02, 0.24 + upgradeLevel * 0.02),
      'library' || 'gallery' => const Offset(0.26, 0.26),
      'fountain' => const Offset(0.22, 0.22),
      'shed' || 'tent' => const Offset(0.24, 0.20),
      'windchime' => const Offset(0.12, 0.24),
      'pier' || 'plaza' => const Offset(0.32, 0.13),
      'flowerbed' => const Offset(0.26, 0.11),
      'mailbox' => const Offset(0.13, 0.13),
      'stone' => const Offset(0.11, 0.11),
      _ => const Offset(0.20, 0.18),
    };
  }
}
