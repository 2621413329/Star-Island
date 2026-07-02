import 'package:flutter/material.dart';

/// 岛屿底座：仅做平面旋转，不绘制阴影。
class WorldPreviewIslandPedestal extends StatelessWidget {
  const WorldPreviewIslandPedestal({
    super.key,
    required this.width,
    required this.child,
    this.rotationRadians = 0,
  });

  final double width;
  final Widget child;
  final double rotationRadians;

  @override
  Widget build(BuildContext context) {
    if (rotationRadians == 0) return child;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateZ(rotationRadians),
      child: child,
    );
  }
}
