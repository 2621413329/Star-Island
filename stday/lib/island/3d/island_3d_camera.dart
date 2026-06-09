import 'package:flame_3d/camera.dart';
import 'package:flame_3d/game.dart';

/// 固定俯视视角，贴近参考图构图。
class Island3DCamera extends CameraComponent3D {
  Island3DCamera({bool compact = false})
      : super(
          position: Vector3(0, compact ? 6.5 : 7.8, compact ? 7.5 : 9.2),
          target: Vector3(0, 0.45, 0),
          projection: CameraProjection.perspective,
          fovY: compact ? 48 : 42,
        );
}
