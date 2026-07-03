import '../../core/growth/growth_system.dart';
import '../config/growth_island_configs.dart';
import '../config/island_visual_config.dart';

/// 主岛交互视口的等级相关缩放（Lv20 贴边建筑完整可见）。
class IslandViewCamera {
  IslandViewCamera._();

  static double islandRadiusForLevel(int level) {
    final clamped = level.clamp(1, GrowthSystem.maxLevel);
    final configs = GrowthIslandConfigs.levels
        .where((config) => config.level <= clamped)
        .toList(growable: false);
    if (configs.isEmpty) return IslandVisualConfig.baseIslandRadius;
    return configs.last.islandRadius;
  }

  /// 默认缩放：岛体越大，初始 zoom 越小，保证边缘建筑在首屏内。
  static double defaultZoomForLevel(int level) {
    final radius = islandRadiusForLevel(level);
    final ratio = IslandVisualConfig.baseIslandRadius / radius;
    return ratio.clamp(0.56, 1.0);
  }

  /// 最小 zoom：高等级允许再缩小一点，查看全岛贴边布局。
  static double minZoomForLevel(int level) {
    if (level >= 18) return 0.50;
    if (level >= 12) return 0.56;
    if (level >= 8) return 0.60;
    return 0.65;
  }

  static double maxZoomForLevel(int level) {
    if (level >= 18) return 2.8;
    return 3.0;
  }

  static double clampZoom(double zoom, int level) =>
      zoom.clamp(minZoomForLevel(level), maxZoomForLevel(level));
}
