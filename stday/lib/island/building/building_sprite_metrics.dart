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
  };

  static double verticalFillRatio(String buildingId) =>
      verticalFillRatios[buildingId] ?? 0.82;

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