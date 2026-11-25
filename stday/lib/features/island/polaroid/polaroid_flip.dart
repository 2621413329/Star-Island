import 'dart:math' as math;

/// 拍立得翻面：角度限制在正面 0 和背面 π 之间。
class PolaroidFlip {
  const PolaroidFlip._();

  static double clampAngle(double radians) {
    if (radians.isNaN) return 0;
    return radians.clamp(0, math.pi);
  }

  /// 松手时吸到更近的一面。正好在中间时留在背面。
  static double snapAngle(double radians) {
    final angle = clampAngle(radians);
    if (angle < math.pi / 2) return 0;
    return math.pi;
  }

  static bool isBack(double radians) => snapAngle(radians) == math.pi;

  /// 横向位移明显大于纵向时，左滑下一张，右滑上一张。
  static int pageDirection({
    required double dx,
    required double dy,
  }) {
    if (dx.abs() < 48 || dx.abs() <= dy.abs()) return 0;
    return dx < 0 ? 1 : -1;
  }
}
