import 'dart:math' as math;

import 'package:flutter/material.dart';

class ConfettiPaperFall extends StatefulWidget {
  const ConfettiPaperFall({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ConfettiPaperFall> createState() => _ConfettiPaperFallState();
}

class _ConfettiPaperFallState extends State<ConfettiPaperFall> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _PaperPainter(_c.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    const colors = [Color(0xFFF0C987), Color(0xFFB8E0D2), Color(0xFFE8C4F0), Color(0xFFFFD4B8)];
    for (var i = 0; i < 12; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = -20 + (size.height + 40) * t * (0.6 + rnd.nextDouble() * 0.4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 12),
        Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) => oldDelegate.t != t;
}
