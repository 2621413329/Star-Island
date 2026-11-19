import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 主岛手势：双指只缩放岛面，放大后单指平移。不旋转。
class IslandGestureSurface extends StatefulWidget {
  const IslandGestureSurface({
    super.key,
    required this.child,
    required this.onTransform,
    this.initialZoom = 1,
    this.initialPan = Offset.zero,
    this.minZoom = 0.88,
    this.maxZoom = 2.6,
    this.enabled = true,
  });

  final Widget child;
  final void Function(double zoom, Offset pan) onTransform;
  final double initialZoom;
  final Offset initialPan;
  final double minZoom;
  final double maxZoom;
  final bool enabled;

  @override
  State<IslandGestureSurface> createState() => _IslandGestureSurfaceState();
}

class _IslandGestureSurfaceState extends State<IslandGestureSurface> {
  late double _zoom;
  late Offset _pan;
  double _startZoom = 1;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
    _pan = widget.initialPan;
  }

  @override
  void didUpdateWidget(covariant IslandGestureSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialZoom != widget.initialZoom ||
        oldWidget.initialPan != widget.initialPan) {
      _zoom = widget.initialZoom.clamp(widget.minZoom, widget.maxZoom);
      _pan = widget.initialPan;
    }
  }

  void _emit() => widget.onTransform(_zoom, _pan);

  Offset _clampPan(Offset pan) {
    if (_zoom <= 1.02) return Offset.zero;
    final box = context.findRenderObject();
    if (box is! RenderBox || box.size.isEmpty) return pan;
    final extra = _zoom - 1;
    final maxX = box.size.width * extra / 2 * 0.92;
    final maxY = box.size.height * extra / 2 * 0.72;
    return Offset(
      pan.dx.clamp(-maxX, maxX),
      pan.dy.clamp(-maxY, maxY),
    );
  }

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
              }
              ..onUpdate = (details) {
                var changed = false;
                if (details.pointerCount >= 2 && details.scale != 1.0) {
                  final next = (_startZoom * details.scale)
                      .clamp(widget.minZoom, widget.maxZoom);
                  if ((next - _zoom).abs() > 0.001) {
                    _zoom = next;
                    changed = true;
                  }
                }
                final canPan = _zoom > 1.02 &&
                    (details.pointerCount >= 2 || details.pointerCount == 1);
                if (canPan && details.focalPointDelta.distance > 0) {
                  final next = _clampPan(_pan + details.focalPointDelta);
                  if ((next - _pan).distance > 0.4) {
                    _pan = next;
                    changed = true;
                  }
                }
                if (_zoom <= 1.02 && _pan != Offset.zero) {
                  _pan = Offset.zero;
                  changed = true;
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
