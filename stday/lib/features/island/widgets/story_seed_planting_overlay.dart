import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/mood_theme.dart';

/// 故事确认归属后，在目标岛上播一段种入：种子落下、落地生光、新芽长出。
class StorySeedPlantingOverlay extends StatefulWidget {
  const StorySeedPlantingOverlay({
    super.key,
    required this.islandName,
    required this.palette,
    required this.onCompleted,
  });

  final String islandName;
  final MoodPalette palette;
  final VoidCallback onCompleted;

  @override
  State<StorySeedPlantingOverlay> createState() =>
      _StorySeedPlantingOverlayState();
}

class _StorySeedPlantingOverlayState extends State<StorySeedPlantingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.islandName.trim().isEmpty ? '这座岛屿' : widget.islandName;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final caption = _captionOpacity(t);
          final grow =
              Curves.easeOutBack.transform(((t - 0.5) / 0.34).clamp(0.0, 1.0));
          final fade = ((t - 0.86) / 0.14).clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final landing = Offset(width * 0.50, height * 0.54);
              const sproutWidth = 156.0;
              const sproutHeight = 148.0;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _SeedPlantingPainter(
                      t: t,
                      palette: widget.palette,
                    ),
                  ),
                  if (grow > 0.02)
                    Positioned(
                      left: landing.dx - sproutWidth / 2,
                      top: landing.dy - sproutHeight,
                      width: sproutWidth,
                      height: sproutHeight,
                      child: Opacity(
                        opacity: (1 - fade).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: grow.clamp(0.0, 1.2),
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.medium,
                          child: Image.asset(
                            'assets/images/decor/grass_01.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: MediaQuery.paddingOf(context).bottom + 108,
                    child: Opacity(
                      opacity: caption,
                      child: Transform.translate(
                        offset: Offset(0, (1 - caption) * 16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  widget.palette.accent.withValues(alpha: 0.28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.palette.accent
                                    .withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Text(
                              '故事种子已种入「$name」',
                              textAlign: TextAlign.center,
                              style: appTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: widget.palette.primary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _captionOpacity(double t) {
    if (t < 0.58) return 0;
    if (t < 0.72) return Curves.easeOut.transform((t - 0.58) / 0.14);
    if (t < 0.88) return 1;
    return (1 - (t - 0.88) / 0.12).clamp(0.0, 1.0);
  }
}

class _SeedPlantingPainter extends CustomPainter {
  _SeedPlantingPainter({required this.t, required this.palette});

  final double t;
  final MoodPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final fall = (t / 0.46).clamp(0.0, 1.0);
    final fallCurve = Curves.easeInCubic.transform(fall);
    final impact = ((t - 0.42) / 0.22).clamp(0.0, 1.0);
    final fade = ((t - 0.86) / 0.14).clamp(0.0, 1.0);
    final veil = (1 - fade) * (0.08 + 0.22 * Curves.easeOut.transform(fall));

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF12324A).withValues(alpha: veil),
    );

    final landing = Offset(size.width * 0.50, size.height * 0.54);
    final start = Offset(size.width * 0.50, size.height * 0.14);
    final seed = Offset(
      lerpDouble(start.dx, landing.dx, fallCurve)! +
          math.sin(fall * math.pi) * size.width * 0.04,
      lerpDouble(start.dy, landing.dy, fallCurve)!,
    );

    if (fall < 1) {
      _drawTrail(canvas, start, seed, fallCurve);
      _drawSeed(canvas, seed, 1 - fall * 0.25);
    }

    if (impact > 0) {
      _drawRings(canvas, landing, impact, 1 - fade);
      _drawMotes(canvas, landing, impact, 1 - fade);
    }
  }

  void _drawTrail(Canvas canvas, Offset start, Offset seed, double progress) {
    const steps = 14;
    for (var i = 0; i < steps; i++) {
      final local = i / steps;
      if (local > progress) break;
      final point = Offset(
        lerpDouble(start.dx, seed.dx, local)! +
            math.sin(local * math.pi) * (seed.dx - start.dx).sign * 8,
        lerpDouble(start.dy, seed.dy, local)!,
      );
      final age = progress - local;
      canvas.drawCircle(
        point,
        2.2 + (1 - age) * 3.5,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - age) * 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawSeed(Canvas canvas, Offset center, double scale) {
    final radius = 11 * scale;
    canvas.drawCircle(
      center,
      radius * 2.4,
      Paint()
        ..color = palette.glow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            palette.accent,
            palette.primary,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.32),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawRings(
      Canvas canvas, Offset landing, double impact, double opacity) {
    for (var i = 0; i < 3; i++) {
      final local = (impact - i * 0.12).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final radius = 18 + local * (70 + i * 28);
      canvas.drawCircle(
        landing,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (5 - local * 3).clamp(1.2, 5)
          ..color = Color.lerp(Colors.white, palette.accent, 0.45)!
              .withValues(alpha: (1 - local) * 0.75 * opacity),
      );
    }
    canvas.drawCircle(
      landing,
      26 + impact * 18,
      Paint()
        ..color = palette.glow.withValues(alpha: (1 - impact) * 0.55 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _drawMotes(
    Canvas canvas,
    Offset landing,
    double impact,
    double opacity,
  ) {
    const count = 16;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + 0.4;
      final lift = impact * (36 + (i % 5) * 14);
      final spread = impact * (18 + (i % 4) * 10);
      final point = landing +
          Offset(math.cos(angle) * spread, -lift + math.sin(angle) * 6);
      canvas.drawCircle(
        point,
        1.6 + (i % 3) * 0.7,
        Paint()
          ..color = (i.isEven ? Colors.white : palette.accent)
              .withValues(alpha: (1 - impact * 0.65) * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SeedPlantingPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.palette != palette;
  }
}
