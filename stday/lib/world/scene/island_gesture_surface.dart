import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 岛屿视口手势：双指缩放与旋转；透传单击给下层 Flame。
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
  late double _zoom;
  late double _rotation;

  double _startZoom = 1;
  double _startRotation = 0;

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

  void _emit() => widget.onTransform(_zoom, _rotation);

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(),
          (ScaleGestureRecognizer instance) {
            instance
              ..onStart = (_) {
                _startZoom = _zoom;
                _startRotation = _rotation;
              }
              ..onUpdate = (details) {
                var changed = false;
                if (details.scale != 1.0) {
                  final next = (_startZoom * details.scale)
                      .clamp(widget.minZoom, widget.maxZoom);
                  if ((next - _zoom).abs() > 0.001) {
                    _zoom = next;
                    changed = true;
                  }
                }
                if (details.rotation != 0.0) {
                  final nextRot = _startRotation + details.rotation;
                  if ((nextRot - _rotation).abs() > 0.001) {
                    _rotation = nextRot;
                    changed = true;
                  }
                }
                if (changed) _emit();
              };
          },
        ),
      },
      child: widget.child,
    );
  }
}
