/// 主岛纵深绘制优先级：Y 越大（越靠屏幕下方）越靠前，应遮挡更靠后的元素。
class SceneDepthPriority {
  SceneDepthPriority._();

  static const int groundBase = 1200;
  static const int skyBase = 9800;
  static const int foregroundGrass = 9600;
  static const int uiEffects = 9900;

  /// 地面建筑 / 装饰 / 角色共用同一纵深轴。
  static int ground(double normalizedDy) {
    return groundBase + (normalizedDy.clamp(0.0, 1.0) * 8000).round();
  }

  /// 天空鸟云蝶萤：保持在地面前景草之上。
  static int sky(double normalizedDy) {
    return skyBase + (normalizedDy.clamp(0.0, 1.0) * 120).round();
  }
}
