import 'dart:math' as math;

import 'package:flame/components.dart';

import 'decor_config.dart';
import 'island_growth_scale_service.dart';

/// 装饰最终尺寸：config.scale × 成长倍率 × randomScale。
class DecorScaleResolver {
  const DecorScaleResolver({
    IslandGrowthScaleService? growthService,
  }) : _growth = growthService ?? const IslandGrowthScaleService();

  final IslandGrowthScaleService _growth;

  static const maxViewportHeightFraction = 0.25;

  /// 分类基准高度（逻辑像素）。
  static double baseHeightFor(DecorCategory category) => switch (category) {
        DecorCategory.grass => 16.0,
        DecorCategory.flower => 18.0,
        DecorCategory.stone => 20.0,
        DecorCategory.bush => 22.0,
        DecorCategory.tree => 62.0,
        DecorCategory.pond => 28.0,
        DecorCategory.special => 20.0,
        DecorCategory.cloud => 36.0,
        DecorCategory.bird => 24.0,
        DecorCategory.butterfly => 16.0,
        DecorCategory.firefly => 10.0,
      };

  /// 首次实例化时生成，基于 id 种子保证跨会话稳定。
  static double randomScaleFor(String decorId) {
    final rng = math.Random(decorId.hashCode);
    return 0.92 + rng.nextDouble() * 0.16;
  }

  /// 成长倍率：1 + ((levelScale - 1) × categoryWeight)
  double growthScaleFor(DecorCategory category, int level) {
    final levelScale = _growth.getLevelScale(level);
    final weight = category.growthWeight;
    return 1 + (levelScale - 1) * weight;
  }

  double finalScale(DecorConfig config, int userLevel) {
    return config.scale *
        growthScaleFor(config.category, userLevel) *
        config.randomScale;
  }

  Vector2 computeSize({
    required DecorConfig config,
    required int userLevel,
    required Vector2 spriteSrcSize,
    required double viewportHeight,
  }) {
    final baseHeight = baseHeightFor(config.category);
    final aspect = spriteSrcSize.x / spriteSrcSize.y;
    final scale = finalScale(config, userLevel);
    var height = baseHeight * scale;
    final maxHeight = viewportHeight * maxViewportHeightFraction;
    if (height > maxHeight) {
      height = maxHeight;
    }
    return Vector2(height * aspect, height);
  }

  /// 建筑渲染高度上限（大型地标不超过视口 25%）。
  static double clampBuildingHeight(double height, double viewportHeight) {
    return math.min(height, viewportHeight * maxViewportHeightFraction);
  }

  static double clampBuildingScale({
    required double height,
    required double viewportHeight,
  }) {
    final maxHeight = viewportHeight * maxViewportHeightFraction;
    if (height <= maxHeight) return 1.0;
    return maxHeight / height;
  }
}
