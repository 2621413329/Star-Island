import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 首页世界地图相机：轻俯视 + 可选平面旋转。
abstract final class WorldPreviewCamera {
  /// 详情页 45° 俯视（与历史一致）。
  static const detailPagePitchRadians = math.pi * 45 / 180;

  /// 首页预览约 22° 俯视（减轻小人/岛面压扁，仍保留群岛地图层次）。
  static const topDownPitchRadians = math.pi * 22 / 180;

  static Matrix4 islandTransform({double yawRadians = 0}) =>
      Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateX(-topDownPitchRadians)
        ..rotateZ(yawRadians);

  static Matrix4 detailPageTransform({double yawRadians = 0}) =>
      Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateX(-detailPagePitchRadians)
        ..rotateZ(yawRadians);

  static Matrix4 topDownTransform() => islandTransform();
}

/// 首页世界拖拽 / 缩放 / 双击复位。
class WorldPreviewCameraController extends StatefulWidget {
  const WorldPreviewCameraController({
    super.key,
    required this.child,
    required this.viewportSize,
    this.enabled = true,
  });

  final Widget child;
  final Size viewportSize;
  final bool enabled;

  @override
  State<WorldPreviewCameraController> createState() =>
      _WorldPreviewCameraControllerState();
}

class _WorldPreviewCameraControllerState
    extends State<WorldPreviewCameraController>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transform;
  AnimationController? _snapBack;
  Animation<Matrix4>? _snapAnimation;

  static const _minScale = 0.88;
  static const _maxScale = 1.42;

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
  }

  @override
  void dispose() {
    _snapBack?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _resetView() {
    _snapBack?.dispose();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final begin = _transform.value;
    final end = Matrix4.identity();
    _snapAnimation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _snapBack!, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (_snapAnimation != null) {
          _transform.value = _snapAnimation!.value;
        }
      });
    _snapBack!.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onDoubleTap: _resetView,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: _minScale,
        maxScale: _maxScale,
        boundaryMargin: const EdgeInsets.all(48),
        clipBehavior: Clip.none,
        child: SizedBox(
          width: widget.viewportSize.width,
          height: widget.viewportSize.height,
          child: widget.child,
        ),
      ),
    );
  }
}
