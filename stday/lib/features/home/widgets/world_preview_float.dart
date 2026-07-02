import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../world/preview/world_island_layout.dart';

/// 岛屿轻微上下浮动。
class WorldPreviewFloat extends StatefulWidget {
  const WorldPreviewFloat({
    super.key,
    required this.child,
    required this.amplitude,
    this.phaseOffset = 0,
    this.enabled = true,
  });

  final Widget child;
  final double amplitude;
  final double phaseOffset;
  final bool enabled;

  @override
  State<WorldPreviewFloat> createState() => _WorldPreviewFloatState();
}

class _WorldPreviewFloatState extends State<WorldPreviewFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.enabled) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant WorldPreviewFloat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.enabled && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final y = math.sin((_ctrl.value + widget.phaseOffset) * math.pi * 2) *
            widget.amplitude;
        return Transform.translate(offset: Offset(0, y), child: child);
      },
      child: widget.child,
    );
  }
}

/// 水面椭圆投影。
class IslandWaterShadow extends StatelessWidget {
  const IslandWaterShadow({
    super.key,
    required this.width,
    required this.depth,
  });

  final double width;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final w = width * (0.92 - depth * 0.12);
    final h = w * 0.22;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A7A).withValues(alpha: 0.22 - depth * 0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        color: const Color(0xFF1A4A7A).withValues(alpha: 0.14 - depth * 0.04),
      ),
    );
  }
}

Offset worldSlotPixel(WorldIslandSlotLayout layout, Size size) {
  return Offset(
    layout.position.dx * size.width,
    layout.position.dy * size.height,
  );
}

Widget maybeBlurDepth({
  required double blurSigma,
  required Widget child,
}) {
  if (blurSigma <= 0.5) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(
      sigmaX: blurSigma,
      sigmaY: blurSigma,
    ),
    child: child,
  );
}
