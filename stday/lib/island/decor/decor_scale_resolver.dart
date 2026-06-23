import 'dart:math' as math;

import 'package:flame/components.dart';

import 'decor_config.dart';
import 'island_growth_scale_service.dart';

/// 装饰最终尺寸：config.scale ÷ 素材内容占比 × 成长倍率 × 低等级填充 × randomScale。
///
/// 所有 PNG 为 800×800，实际绘制内容仅占画布一部分；[spriteFillRatios] 记录
/// 不透明内容高度占比，避免留白导致同类装饰视觉大小失真。
/// [DecorConfig.scale] 表示相对分类基准的「目标视觉系数」（对标 LV1 草地体系）。
class DecorScaleResolver {
  const DecorScaleResolver({
    IslandGrowthScaleService? growthService,
  }) : _growth = growthService ?? const IslandGrowthScaleService();

  final IslandGrowthScaleService _growth;

  static const maxViewportHeightFraction = 0.25;

  /// 800×800 素材中不透明内容的垂直占比（alpha bbox height / image height）。
  static const spriteFillRatios = <String, double>{
    'grass_01': 0.7025,
    'grass_02': 0.6787,
    'grass_03': 0.9912,
    'grass_04': 0.7738,
    'flower_01': 0.8880,
    'flower_02': 0.8880,
    'flower_03': 0.8880,
    'flower_field_01': 0.8880,
    'rare_flower_01': 1.0,
    'stone_01': 0.74,
    'stone_02': 0.7762,
    'bush_01': 0.985,
    'bush_02': 0.8063,
    'bush_03': 0.9387,
    'tree_small_01': 1.0,
    'tree_small_02': 1.0,
    'tree_small_03': 1.0,
    'tree_small_04': 1.0,
    'tree_large_01': 1.0,
    'tree_large_02': 0.8688,
    'life_tree_01': 0.9313,
    'mushroom_01': 0.5988,
    'mushroom_02': 0.875,
    'wood_01': 0.8,
    'fallen_leaf_01': 1.0,
    'butterfly_01': 0.975,
    'bird_01': 1.0,
    'bird_02': 0.8875,
    'bird_03': 1.0,
    'seagull_group_01': 0.9600,
    'cloud_01': 0.7512,
    'cloud_02': 0.49,
    'cloud_03': 0.8237,
    'cloud_04': 0.8638,
    'rainbow_cloud_01': 0.7075,
    'pond_01': 0.6275,
    'firefly_01': 0.73,
  };

  static double spriteFillRatioFor(String decorId) =>
      spriteFillRatios[decorId] ?? 1.0;

  /// 分类基准高度（逻辑像素）。
  static double baseHeightFor(DecorCategory category) => switch (category) {
        DecorCategory.grass => 18.0,
        DecorCategory.flower => 20.0,
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

  /// Lv1–Lv7 低等级填充加成：小草/花朵等配饰更大，Lv8 起恢复常态。
  double lowLevelFillBoost(DecorCategory category, int level) {
    if (!category.receivesLowLevelFillBoost || level >= 8) return 1.0;
    const peakBoost = 1.55;
    final t = ((level - 1) / 7.0).clamp(0.0, 1.0);
    final smooth = t * t * (3 - 2 * t);
    return peakBoost + (1.0 - peakBoost) * smooth;
  }

  double finalScale(DecorConfig config, int userLevel) {
    final fill = spriteFillRatioFor(config.id);
    return (config.scale / fill) *
        growthScaleFor(config.category, userLevel) *
        lowLevelFillBoost(config.category, userLevel) *
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
