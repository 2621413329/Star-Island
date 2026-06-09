import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/graphics.dart';

/// 空容器：组合多个 3D 子节点（树、岩石组等）。
class Island3DGroup extends Object3D {
  Island3DGroup({
    super.position,
    super.scale,
    super.rotation,
    super.children,
  });

  @override
  void bind(GraphicsDevice device) {}

  @override
  bool shouldCull(CameraComponent3D camera) => false;
}
