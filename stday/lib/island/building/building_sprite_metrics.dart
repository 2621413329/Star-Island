/// 主岛建筑 PNG 内容度量：统一缩放与 footprint 宽高比。
///
/// 素材为 800×800 画布，实际建筑内容仅占一部分；渲染与碰撞均用
/// **单一 scale**（以高度为基准），宽度由 [contentAspectRatio] 推导。
class BuildingSpriteMetrics {
  BuildingSpriteMetrics._();

  /// 不透明内容宽 / 高（alpha bbox 近似）。
  static const contentAspectRatios = <String, double>{
    'lighthouse': 0.34,
    'growth_clocktower': 0.38,
    'dream_observatory': 0.72,
    'growth_academy': 0.98,
    'lighthouse_base': 0.52,
    'growth_house_lv2': 0.92,
    'growth_house': 0.88,
    'library_seed': 0.82,
    // 与梦想观测台接近，避免画廊显得过扁。
    'memory_gallery': 0.72,
    'record_shed': 0.86,
    'quiet_tent': 0.90,
    'memory_fountain': 0.88,
    'emotion_windchime': 0.42,
    'starter_stone': 0.95,
    'memory_mailbox': 0.78,
    'harbor_pier': 1.35,
    'story_plaza': 1.20,
    'companion_plaza': 1.18,
    'habit_flowerbed': 1.05,
    'growth_tree': 1.0,
  };

  static double contentAspectRatio(String buildingId, {double? imageAspect}) {
    if (imageAspect != null && imageAspect > 0) {
      return imageAspect;
    }
    return contentAspectRatios[buildingId] ?? 0.78;
  }

  /// 800×800 画布中不透明内容的垂直占比。
  static const verticalFillRatios = <String, double>{
    'lighthouse': 0.92,
    'growth_clocktower': 0.90,
    'dream_observatory': 0.78,
    'growth_academy': 0.72,
    'harbor_pier': 0.35,
    'story_plaza': 0.28,
    'companion_plaza': 0.28,
    'starter_stone': 0.55,
    'growth_tree': 1.0,
  };

  static double verticalFillRatio(String buildingId) =>
      verticalFillRatios[buildingId] ?? 0.82;

  /// 画布底边到不透明底座的比例。脚点贴岛面时要把图下移这么多。
  static const baselineInsets = <String, double>{
    'companion_plaza': 0.165,
    'dream_observatory': 0.046,
    'emotion_windchime': 0.065,
    'growth_academy': 0.077,
    'growth_clocktower': 0.052,
    'growth_house': 0.140,
    'growth_house_lv2': 0.081,
    'habit_flowerbed': 0.212,
    'harbor_pier': 0.211,
    'library_seed': 0.077,
    'lighthouse': 0.086,
    'lighthouse_base': 0.086,
    'memory_fountain': 0.227,
    'memory_gallery': 0.095,
    'memory_mailbox': 0.086,
    'quiet_tent': 0.154,
    'record_shed': 0.133,
    'starter_stone': 0.091,
    'story_plaza': 0.127,
  };

  static double baselineInset(String buildingId) =>
      baselineInsets[buildingId] ?? 0.10;

  /// 画布宽高比。广场和栈桥是 1536×1024，其余建筑是正方形。
  static double canvasAspect(String buildingId) {
    return switch (buildingId) {
      'companion_plaza' || 'harbor_pier' || 'story_plaza' => 1536 / 1024,
      _ => 1,
    };
  }

  /// 不透明像素占画布的比例：左、上、右、下。底边和 [baselineInset] 对齐脚点。
  ///
  /// 取自素材 alpha ≥ 40 的外框。热区用这个框，不再含脚下和两侧的透明边。
  static const opaqueNorm = <String, (double, double, double, double)>{
    'companion_plaza': (0.136, 0.195, 0.857, 0.835),
    'dream_observatory': (0.047, 0.034, 0.953, 0.954),
    'emotion_windchime': (0.137, 0.047, 0.863, 0.935),
    'growth_academy': (0.068, 0.090, 0.929, 0.923),
    'growth_clocktower': (0.105, 0.041, 0.890, 0.948),
    'growth_house': (0.087, 0.146, 0.896, 0.860),
    'growth_house_lv2': (0.016, 0.056, 0.969, 0.919),
    'habit_flowerbed': (0.104, 0.260, 0.895, 0.788),
    'harbor_pier': (0.215, 0.180, 0.785, 0.789),
    'library_seed': (0.053, 0.090, 0.951, 0.923),
    'lighthouse': (0.099, 0.080, 0.895, 0.914),
    'lighthouse_base': (0.099, 0.080, 0.895, 0.914),
    'memory_fountain': (0.135, 0.225, 0.863, 0.773),
    'memory_gallery': (0.040, 0.089, 0.959, 0.905),
    'memory_mailbox': (0.081, 0.084, 0.917, 0.914),
    'quiet_tent': (0.052, 0.141, 0.949, 0.846),
    'record_shed': (0.078, 0.176, 0.916, 0.866),
    'starter_stone': (0.110, 0.118, 0.886, 0.909),
    'story_plaza': (0.068, 0.169, 0.930, 0.873),
  };

  static (double, double, double, double) opaqueNormFor(String buildingId) =>
      opaqueNorm[buildingId] ?? (0, 0, 1, 1);

  /// 由目标高度与宽高比得到统一 footprint（宽 × 高）。
  static ({double width, double height}) uniformSize({
    required String buildingId,
    required double targetHeight,
    double? imageAspect,
  }) {
    final aspect = contentAspectRatio(buildingId, imageAspect: imageAspect);
    return (width: targetHeight * aspect, height: targetHeight);
  }

}