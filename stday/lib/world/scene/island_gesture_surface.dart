import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 岛屿视口手势：双指缩放、单指绕岛心旋转；[Listener] 透传点击给下层 Flame。
class IslandGestureSurface extends StatefulWidget {
  const IslandGestureSurface({
    super.key,
    required this.child,
    required this.onTransform,
    this.initialZoom = 1,
    this.initialRotation = 0,
    this.minZoom = 0.65,
    this.maxZoom = 3.0,
    this.enabled = true,
  });

  final Widget child;
  final void Function(double zoom, double rotationRadians) onTransform;
  final double initialZoom;
  final double initialRotation;
  final double minZoom;
  final double maxZoom;
  final bool enabled;

  @override
  State<IslandGestureSurface> createState() => _IslandGestureSurfaceState();
}

class _IslandGestureSurfaceState extends State<IslandGestureSurface> {
  final Map<int, Offset> _pointers = {};

  late double _zoom;
  late double _rotation;

  double _startZoom = 1;
  double _startRotation = 0;
  double? _startSpan;
  double? _startAngle;

  Size? _size;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
    _rotation = widget.initialRotation;
    _startZoom = _zoom;
    _startRotation = _rotation;
  }

  @override
  void didUpdateWidget(covariant IslandGestureSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialZoom != widget.initialZoom ||
        oldWidget.initialRotation != widget.initialRotation) {
      _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
      _rotation = widget.initialRotation;
      _startZoom = _zoom;
      _startRotation = _rotation;
    }
  }

  Offset get _islandPivot {
    final s = _size!;
    return Offset(s.width * 0.5, s.height * 0.55);
  }

  void _emit() => widget.onTransform(_zoom, _rotation);

  void _resetBaseline() {
    _startZoom = _zoom;
    _startRotation = _rotation;
    _startSpan = _pointerSpan();
    _startAngle = _gestureAngle();
  }

  double? _pointerSpan() {
    if (_pointers.length < 2) return null;
    final pts = _pointers.values.toList();
    return (pts[0] - pts[1]).distance;
  }

  double? _gestureAngle() {
    if (_size == null) return null;
    if (_pointers.length >= 2) {
      final pts = _pointers.values.toList();
      return math.atan2(pts[1].dy - pts[0].dy, pts[1].dx - pts[0].dx);
    }
    if (_pointers.length == 1) {
      final p = _pointers.values.first;
      final c = _islandPivot;
      return math.atan2(p.dy - c.dy, p.dx - c.dx);
    }
    return null;
  }

  void _applyGesture() {
    if (!widget.enabled || _size == null) return;

    var changed = false;

    if (_pointers.length >= 2) {
      final span = _pointerSpan();
      if (span != null &&
          _startSpan != null &&
          _startSpan! > 8 &&
          span > 8) {
        final next = (_startZoom * (span / _startSpan!))
            .clamp(widget.minZoom, widget.maxZoom);
        if ((next - _zoom).abs() > 0.001) {
          _zoom = next;
          changed = true;
        }
      }
      final angle = _gestureAngle();
      if (angle != null && _startAngle != null) {
        final nextRot = _startRotation + (angle - _startAngle!);
        if ((nextRot - _rotation).abs() > 0.001) {
          _rotation = nextRot;
          changed = true;
        }
      }
    } else if (_pointers.length == 1) {
      final angle = _gestureAngle();
      if (angle != null && _startAngle != null) {
        final nextRot = _startRotation + (angle - _startAngle!);
        if ((nextRot - _rotation).abs() > 0.001) {
          _rotation = nextRot;
          changed = true;
        }
      }
    }

    if (changed) {
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _pointers[e.pointer] = e.localPosition;
            _resetBaseline();
          },
          onPointerMove: (e) {
            if (!_pointers.containsKey(e.pointer)) return;
            _pointers[e.pointer] = e.localPosition;
            _applyGesture();
          },
          onPointerUp: (e) {
            _pointers.remove(e.pointer);
            _resetBaseline();
          },
          onPointerCancel: (e) {
            _pointers.remove(e.pointer);
            _resetBaseline();
          },
          child: widget.child,
        );
      },
    );
  }
}
