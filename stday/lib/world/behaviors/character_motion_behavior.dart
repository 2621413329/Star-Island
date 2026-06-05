import 'dart:math' as math;
import 'dart:ui';

import '../engine/world_state.dart';

class CharacterMotionFrame {
  const CharacterMotionFrame({
    required this.bob,
    required this.wander,
  });

  final double bob;
  final Offset wander;
}

/// 纯函数行为：根据角色运动参数和时间，计算当前位移。
class CharacterMotionBehavior {
  const CharacterMotionBehavior();

  CharacterMotionFrame sample({
    required CharacterMotion motion,
    required double time,
    required double seed,
  }) {
    final bob = math.sin(time + seed * 0.37) * motion.bobAmplitude;
    final wanderAngle = time * motion.wanderSpeed + seed;
    final wander = Offset(
      math.cos(wanderAngle) * motion.wanderRadius,
      math.sin(wanderAngle * 0.7 + seed * 0.17) * (motion.wanderRadius * 0.5),
    );
    return CharacterMotionFrame(bob: bob, wander: wander);
  }
}
