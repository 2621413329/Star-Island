/// 首页群岛视觉参数：按分类与远近区分缩放/旋转，不改变业务数据。
abstract final class WorldIslandVisualProfile {
  /// 主岛相对副岛基准约 1.65×（避免遮挡副岛）。
  static const mainScale = 1.65;

  /// 副岛分类微调（在 depthScale 之上 ±5%）。
  static double categoryScale(String? categoryId) {
    return switch (categoryId) {
      'work' => 1.04,
      'finance' || 'wealth' => 1.02,
      'health' => 0.98,
      'study' => 0.96,
      'social' => 1.0,
      'life' => 0.97,
      _ => 1.0,
    };
  }

  static double categoryRotation(String? categoryId) {
    return switch (categoryId) {
      'work' => -0.09,
      'study' => 0.085,
      'finance' || 'wealth' => 0.07,
      'health' => -0.05,
      'social' => 0.06,
      'life' => -0.04,
      _ => 0.03,
    };
  }

  static double combinedRotation({
    required double layoutRotation,
    String? categoryId,
  }) {
    return layoutRotation + categoryRotation(categoryId);
  }

  static double floatAmplitude({required bool isMain, String? categoryId}) {
    if (isMain) return 0.28;
    return 0.22;
  }
}
