import 'dart:math' as math;
import 'dart:ui';

/// 主角站在岛面上：呼吸、左右张望，隔一阵轻轻跳一下。
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

  /// 比旧版 (0.5, 0.52) 下移，脚底对齐岛面活动区。
  static const defaultBase = Offset(0.50, 0.66);

  /// 归一化竖直浮动幅度（相对场景高度）。
  static const bobAmplitude = 0.0045;

  final Offset base;

  ProtagonistBehaviorSample sample(double time) {
    final cycle = time % 9.0;
    var bob = math.sin(time * 1.6) * bobAmplitude;
    var yaw = math.sin(time * 0.65) * 0.22;
    var mode = 'breathe';
    if (cycle > 6.2 && cycle < 7.15) {
      mode = 'look';
      yaw = -0.62;
    } else if (cycle > 7.15 && cycle < 8.05) {
      mode = 'look';
      yaw = 0.62;
    } else if (cycle > 8.05) {
      mode = 'hop';
      final t = (cycle - 8.05) / 0.95;
      bob -= math.sin(t * math.pi) * 0.016;
    }
    return ProtagonistBehaviorSample(
      normalizedPos: base,
      facingYaw: yaw,
      bob: bob,
      mode: mode,
    );
  }
}
