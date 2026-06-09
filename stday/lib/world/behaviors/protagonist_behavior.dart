import 'dart:math' as math;
import 'dart:ui';

/// 主角行为：散步 → 看海 → 驻足，循环播放。
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
  const ProtagonistBehavior({
    this.base = const Offset(0.5, 0.52),
    this.strollRadius = 0.055,
  });

  final Offset base;
  final double strollRadius;

  static const _cycleSeconds = 42.0;

  ProtagonistBehaviorSample sample(double time) {
    final t = time % _cycleSeconds;

    if (t < 26) {
      final phase = t / 26 * math.pi * 2;
      final pos = base +
          Offset(
            math.cos(phase) * strollRadius,
            math.sin(phase) * strollRadius * 0.55,
          );
      return ProtagonistBehaviorSample(
        normalizedPos: pos,
        facingYaw: math.atan2(
          -math.sin(phase) * strollRadius * 0.55,
          math.cos(phase) * strollRadius,
        ),
        bob: math.sin(time * 2.2) * 0.012,
        mode: 'stroll',
      );
    }

    if (t < 36) {
      final blend = ((t - 26) / 10).clamp(0.0, 1.0);
      final seaGaze = Offset(base.dx, base.dy + 0.07);
      final pos = Offset.lerp(base, seaGaze, blend)!;
      return ProtagonistBehaviorSample(
        normalizedPos: pos,
        facingYaw: math.pi * 0.5,
        bob: math.sin(time * 1.4) * 0.008,
        mode: 'gaze_sea',
      );
    }

    final seaGaze = Offset(base.dx, base.dy + 0.07);
    return ProtagonistBehaviorSample(
      normalizedPos: seaGaze,
      facingYaw: math.pi * 0.5,
      bob: math.sin(time * 1.1) * 0.006,
      mode: 'idle',
    );
  }
}
