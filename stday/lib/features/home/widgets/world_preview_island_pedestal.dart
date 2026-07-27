import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 岛屿底座：平面旋转 + 岛底治愈风同心水波纹。
class WorldPreviewIslandPedestal extends StatefulWidget {
  const WorldPreviewIslandPedestal({
    super.key,
    required this.width,
    required this.child,
    this.rotationRadians = 0,
    this.isMain = false,
    this.animateRipple = true,
  });

  final double width;
  final Widget child;
  final double rotationRadians;
  final bool isMain;
  /// 首页群岛关闭动画，避免每岛持续重绘。
  final bool animateRipple;

  @override
  State<WorldPreviewIslandPedestal> createState() =>
      _WorldPreviewIslandPedestalState();
}

class _WorldPreviewIslandPedestalState extends State<WorldPreviewIslandPedestal>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animateRipple) {
      _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.isMain ? 4200 : 3600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget island = widget.child;
    if (widget.rotationRadians != 0) {
      island = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(widget.rotationRadians),
        child: island,
      );
    }

    final ripples = CustomPaint(
      size: Size(widget.width, widget.width * 0.72),
      painter: _IslandWaterRipplePainter(
        phase: _ctrl?.value ?? 0.18,
        isMain: widget.isMain,
      ),
    );

    if (_ctrl == null) {
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [ripples, island],
      );
    }

    return AnimatedBuilder(
      animation: _ctrl!,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(widget.width, widget.width * 0.72),
              painter: _IslandWaterRipplePainter(
                phase: _ctrl!.value,
                isMain: widget.isMain,
              ),
            ),
            child!,
          ],
        );
      },
      child: island,
    );
  }
}

/// 岛底同心椭圆波纹（参考治愈风群岛水痕）。
class _IslandWaterRipplePainter extends CustomPainter {
  _IslandWaterRipplePainter({
    required this.phase,
    required this.isMain,
  });

  final double phase;
  final bool isMain;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.58);
    final baseW = size.width * (isMain ? 0.78 : 0.72);
    final baseH = baseW * 0.28;
    final ringCount = isMain ? 4 : 3;

    // 接触水面的柔光椭圆。
    final glowRect = Rect.fromCenter(
      center: center,
      width: baseW * 0.92,
      height: baseH * 0.85,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: isMain ? 0.22 : 0.16),
            const Color(0xFFB8E6FF).withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(glowRect),
    );

    for (var i = 0; i < ringCount; i++) {
      final t = (phase + i / ringCount) % 1.0;
      final expand = 0.78 + t * 0.55;
      final alpha = (1.0 - t) * (isMain ? 0.34 : 0.28);
      final rect = Rect.fromCenter(
        center: center,
        width: baseW * expand,
        height: baseH * expand,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isMain ? 1.6 : 1.35
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
      );

      // 内圈更亮一点，接近参考图的水痕高光。
      if (i == 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: baseW * 0.70,
            height: baseH * 0.70,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = Colors.white.withValues(alpha: 0.22),
        );
      }
    }

    // 外圈稀疏星点，增强治愈感。
    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 4; i++) {
      final a = phase * math.pi * 2 + i * math.pi / 2.2;
      final r = 0.42 + (i % 2) * 0.08;
      final p = Offset(
        center.dx + math.cos(a) * baseW * r * 0.52,
        center.dy + math.sin(a) * baseH * r * 0.9,
      );
      canvas.drawCircle(p, isMain ? 1.4 : 1.1, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _IslandWaterRipplePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.isMain != isMain;
  }
}
