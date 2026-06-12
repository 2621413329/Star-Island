import 'dart:math' as math;
import 'dart:ui';

/// 首页主角行为：固定站在成长树前，只保留轻微呼吸。
class ProtagonistBehaviorSample {
  const ProtagonistBehaviorSample({
    required this.normalizedPos,
    required this.facingYaw,
    required this.bob,
    required this.mode,
  });

  final Offset normalizedPos;

  /// 绕 Y 轴朝向（弧度），0 = +Z。
  final double facingYaw;
  final double bob;
  final String mode;
}

class ProtagonistBehavior {
  const ProtagonistBehavior({this.base = defaultBase});

  /// 比旧版 (0.5, 0.52) 下移约一个主角身高，站在岛面活动区。
  static const defaultBase = Offset(0.5, 0.63);

  /// 归一化竖直浮动幅度（相对场景高度）。
  static const bobAmplitude = 0.014;

  final Offset base;

  ProtagonistBehaviorSample sample(double time) {
    return ProtagonistBehaviorSample(
      normalizedPos: base,
      facingYaw: 0,
      bob: math.sin(time * 1.1) * bobAmplitude,
      mode: 'idle',
    );
  }
}
