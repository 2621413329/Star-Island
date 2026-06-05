import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/growth/growth_system.dart';
import '../core/models/mood_island_config.dart';
import '../core/theme/mood_theme.dart';
import '../world/island/island_shape_profile.dart';
import 'serene_lagoon_island_painter.dart';

/// 首页成长岛绘制风格。
enum GrowthIslandVisualStyle {
  /// 侧壁岩层 + 土丘（原 2.5D 浮岛）。
  classic,
  /// 俯视浅海、乳白沙滩、柔草绒面。
  sereneLagoon,
}

/// 首页成长岛：有机浮岛轮廓 + 草地 / 土层 / 岩层 / 成长核心 + 等级装饰。
class GrowthIslandWidget extends StatefulWidget {
  const GrowthIslandWidget({
    super.key,
    required this.islandStyle,
    this.stage = const IslandGrowthStage(1),
    this.size,
    this.width,
    this.compact = false,
    this.visualStyle,
  });

  final MoodIslandConfig islandStyle;
  final IslandGrowthStage stage;

  /// 固定绘制区域；未指定时用 [width] 与默认高宽比推算。
  final Size? size;
  final double? width;

  /// 首页紧凑模式：更小、更浅悬崖，避免压住下方文案。
  final bool compact;

  /// 未指定时默认 [classic]（3D 侧壁浮岛）；[sereneLagoon] 为俯视 2D 备用。
  final GrowthIslandVisualStyle? visualStyle;

  static const double aspectRatio = 0.72;

  @override
  State<GrowthIslandWidget> createState() => _GrowthIslandWidgetState();
}

class _GrowthIslandWidgetState extends State<GrowthIslandWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  GrowthIslandVisualStyle get _resolvedVisual =>
      widget.visualStyle ?? GrowthIslandVisualStyle.classic;

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size?.width ?? 280;
    final h = widget.size?.height ?? w / GrowthIslandWidget.aspectRatio;
    const palette = defaultPalette;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) {
        final t = _float.value;
        final bob = math.sin(t * 2 * math.pi) * (widget.compact ? 1.5 : 4);
        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: w,
            height: h,
            child: ClipRect(
              child: CustomPaint(
                painter: _GrowthIslandPainter(
                  style: widget.islandStyle,
                  stage: widget.stage,
                  palette: palette,
                  anim: t,
                  compact: widget.compact,
                  visualStyle: _resolvedVisual,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GrowthIslandPainter extends CustomPainter {
  _GrowthIslandPainter({
    required this.style,
    required this.stage,
    required this.palette,
    required this.anim,
    this.compact = false,
    this.visualStyle = GrowthIslandVisualStyle.classic,
  });

  final MoodIslandConfig style;
  final IslandGrowthStage stage;
  final MoodPalette palette;
  final double anim;
  final bool compact;
  final GrowthIslandVisualStyle visualStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (visualStyle == GrowthIslandVisualStyle.sereneLagoon) {
      SereneLagoonIslandPainter.paint(canvas, size, style: style, anim: anim);
      return;
    }
    final drawH = size.height * (compact ? 0.72 : 0.82);
    final drawSize = Size(size.width, drawH);
    canvas.save();
    canvas.translate(0, size.height * (compact ? 0.04 : 0.02));

    final topPath =
        IslandShapeProfile.resolve(style).buildTopPath(drawSize, compact: compact);
    final bounds = topPath.getBounds();
    final cliff = drawH * (compact ? 0.11 : 0.18);
    final center = Offset(drawSize.width * 0.5, bounds.center.dy + bounds.height * 0.08);

    _drawWaterReflection(canvas, drawSize, size, topPath, cliff);
    _drawCliffAndRocks(canvas, drawSize, topPath, center, cliff);
    _drawGrassSurface(canvas, topPath, bounds);
    _drawSoilRim(canvas, topPath);
    _drawGrowthCore(canvas, bounds);
    _drawStageDecor(canvas, bounds);

    if (compact) {
      final waterTop = drawSize.height + cliff * 0.15;
      canvas.drawRect(
        Rect.fromLTWH(0, waterTop, drawSize.width, size.height - waterTop),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              style.sea.withValues(alpha: 0.14),
              style.sea.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, waterTop, drawSize.width, 36)),
      );
    }

    canvas.restore();
  }

  /// 不规则土丘顶面：上凸、侧边略陡，更接近「小岛」而非圆盘按钮。
  void _drawWaterReflection(
    Canvas canvas,
    Size drawSize,
    Size widgetSize,
    Path topPath,
    double cliff,
  ) {
    final waterY = drawSize.height + cliff * 0.35;
    final shadowRect = Rect.fromCenter(
      center: Offset(drawSize.width * 0.5, waterY + widgetSize.height * 0.04),
      width: drawSize.width * 0.5,
      height: drawSize.height * 0.07,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = ui.Gradient.radial(
          shadowRect.center,
          shadowRect.width * 0.5,
          [
            const Color(0xFF8D6E63).withValues(alpha: 0.28),
            Colors.transparent,
          ],
        ),
    );

    canvas.save();
    canvas.translate(0, cliff * 0.55);
    canvas.scale(1, -0.32);
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.grass.withValues(alpha: 0.2),
            style.sea.withValues(alpha: 0.06),
          ],
        ).createShader(topPath.getBounds()),
    );
    canvas.restore();

    final ripplePhase = (anim * 2 * math.pi);
    for (var i = 0; i < 3; i++) {
      final p = ((ripplePhase / (2 * math.pi) + i * 0.33) % 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(drawSize.width * 0.5, waterY + 6),
          width: drawSize.width * (0.32 + p * 0.16),
          height: drawSize.height * (0.045 + p * 0.025),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: (1 - p) * 0.22),
      );
    }
  }

  void _drawCliffAndRocks(
    Canvas canvas,
    Size size,
    Path topPath,
    Offset center,
    double cliff,
  ) {
    final metrics = topPath.computeMetrics().first;
    const steps = 56;
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: compact
            ? [
                Color.lerp(style.sand, const Color(0xFFBCAAA4), 0.35)!,
                const Color(0xFF8D6E63),
                const Color(0xFF6D4C41),
                const Color(0xFF78909C),
              ]
            : [
                Color.lerp(style.sand, const Color(0xFFA1887F), 0.25)!,
                const Color(0xFF6D4C41),
                const Color(0xFF5D4037),
                const Color(0xFF4E342E),
                const Color(0xFF78909C),
                const Color(0xFF546E7A),
              ],
        stops: compact
            ? const [0.0, 0.35, 0.7, 1.0]
            : const [0.0, 0.22, 0.45, 0.62, 0.82, 1.0],
      ).createShader(Offset.zero & size);

    for (var i = 0; i < steps; i++) {
      final t0 = i / steps;
      final t1 = (i + 1) / steps;
      final p0 = metrics.getTangentForOffset(metrics.length * t0)!.position;
      final p1 = metrics.getTangentForOffset(metrics.length * t1)!.position;
      final taper = compact ? 0.32 : 0.48;
      final b0 = _extrude(p0, center, cliff, taper);
      final b1 = _extrude(p1, center, cliff, taper);
      final quad = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(b1.dx, b1.dy)
        ..lineTo(b0.dx, b0.dy)
        ..close();
      canvas.drawPath(quad, wallPaint);

      if (i % 7 == 0) {
        final mid = Offset(
          (b0.dx + b1.dx) * 0.5,
          (b0.dy + b1.dy) * 0.5,
        );
        _drawRock(canvas, mid, 5 + (i % 3) * 2.0);
      }
    }

    final rockBase = Path();
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final tan = metrics.getTangentForOffset(metrics.length * t)!;
      final b = _extrude(tan.position, center, cliff * 0.95, compact ? 0.34 : 0.52);
      if (i == 0) {
        rockBase.moveTo(b.dx, b.dy);
      } else {
        rockBase.lineTo(b.dx, b.dy);
      }
    }
    rockBase.close();
    canvas.drawPath(
      rockBase,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6D4C41).withValues(alpha: 0.9),
            const Color(0xFF455A64),
          ],
        ).createShader(rockBase.getBounds()),
    );
  }

  void _drawGrassSurface(Canvas canvas, Path topPath, Rect bounds) {
    canvas.save();
    canvas.clipPath(topPath);

    final grassLight = Color.lerp(style.grass, Colors.white, 0.42)!;
    final grassMid = style.grass;
    final grassDark = Color.lerp(style.grass, const Color(0xFF2E7D32), 0.28)!;

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = (compact
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [grassLight, grassMid, grassDark],
                    stops: const [0.0, 0.5, 1.0],
                  )
                : RadialGradient(
                    center: const Alignment(-0.15, -0.45),
                    radius: 1.05,
                    colors: [grassLight, grassMid, grassDark],
                    stops: const [0.0, 0.55, 1.0],
                  ))
            .createShader(bounds),
    );

    final bladePaint = Paint()
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var i = 0; i < (compact ? 32 : 48); i++) {
      final x = bounds.left + rnd.nextDouble() * bounds.width;
      final y = bounds.top + rnd.nextDouble() * bounds.height * 0.85;
      if (!topPath.contains(Offset(x, y))) continue;
      bladePaint.color = grassDark.withValues(alpha: 0.25 + rnd.nextDouble() * 0.2);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + rnd.nextDouble() * 3 - 1.5, y - 4 - rnd.nextDouble() * 5),
        bladePaint,
      );
    }

    canvas.drawPath(
      topPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  void _drawSoilRim(Canvas canvas, Path topPath) {
    final rimW = compact ? 4.0 : 6.0;
    canvas.drawPath(
      topPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimW
        ..color = Color.lerp(style.sand, const Color(0xFF6D4C41), 0.55)!
            .withValues(alpha: compact ? 0.65 : 0.82),
    );
  }

  void _drawGrowthCore(Canvas canvas, Rect bounds) {
    final pulse = 1 + 0.06 * math.sin(anim * 2 * math.pi);
    final coreCenter = Offset(
      bounds.center.dx,
      bounds.center.dy + bounds.height * 0.06,
    );
    final r = math.min(bounds.width, bounds.height) * (compact ? 0.08 : 0.11) * pulse;

    canvas.drawCircle(
      coreCenter + const Offset(0, 3),
      r * 1.1,
      Paint()
        ..color = style.accent.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(
      coreCenter,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            palette.glow,
            style.accent,
            style.accent.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: coreCenter, radius: r)),
    );

    if (stage.showGlowCore) {
      final glow = r * (1.35 + 0.08 * math.sin(anim * 2 * math.pi * 1.3));
      canvas.drawCircle(
        coreCenter,
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [
              palette.glow.withValues(alpha: 0.45),
              palette.glow.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: coreCenter, radius: glow)),
      );
      _drawGlowStone(canvas, coreCenter + Offset(r * 1.35, -r * 0.2), r * 0.35);
    }
  }

  void _drawGlowStone(Canvas canvas, Offset c, double s) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.7, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.9)
      ..lineTo(c.dx - s * 0.65, c.dy + s * 0.1)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, palette.glow, style.accent],
        ).createShader(Rect.fromCenter(center: c, width: s * 2, height: s * 2)),
    );
  }

  void _drawStageDecor(Canvas canvas, Rect bounds) {
    final scale = bounds.width / 200;

    if (stage.showSapling) {
      _drawSapling(
        canvas,
        Offset(bounds.center.dx - bounds.width * 0.06, bounds.top + bounds.height * 0.08),
        scale * (compact ? 0.88 : 1),
      );
    } else if (compact) {
      _drawTinySprout(canvas, Offset(bounds.center.dx + bounds.width * 0.12, bounds.top + bounds.height * 0.2));
    }

    if (stage.showFlowers) {
      _drawFlower(canvas, Offset(bounds.left + bounds.width * 0.28, bounds.bottom - bounds.height * 0.22), style.flower);
      _drawFlower(canvas, Offset(bounds.right - bounds.width * 0.3, bounds.bottom - bounds.height * 0.28), style.flower);
      _drawFlower(canvas, Offset(bounds.center.dx + bounds.width * 0.18, bounds.bottom - bounds.height * 0.18), style.flower);
    }

    if (stage.showCabin) {
      _drawCabin(
        canvas,
        Offset(bounds.right - bounds.width * 0.32, bounds.bottom - bounds.height * 0.32),
        scale * 1.1,
      );
    }

    if (stage.showWindmill) {
      _drawWindmill(
        canvas,
        Offset(bounds.left + bounds.width * 0.2, bounds.bottom - bounds.height * 0.35),
        scale,
      );
    }
  }

  void _drawTinySprout(Canvas canvas, Offset base) {
    canvas.drawLine(
      base,
      base + const Offset(0, 8),
      Paint()
        ..strokeWidth = 1.4
        ..color = const Color(0xFF558B2F),
    );
    canvas.drawCircle(base + const Offset(0, -3), 3.5, Paint()..color = Color.lerp(style.grass, Colors.white, 0.25)!);
  }

  void _drawSapling(Canvas canvas, Offset base, double scale) {
    final trunkW = 5 * scale;
    final trunkH = 22 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base + Offset(0, trunkH * 0.5),
          width: trunkW,
          height: trunkH,
        ),
        Radius.circular(trunkW * 0.3),
      ),
      Paint()..color = const Color(0xFF5D4037),
    );

    void foliage(double w, double h, Offset o, Color c) {
      final path = Path()
        ..moveTo(o.dx, o.dy + h)
        ..quadraticBezierTo(o.dx - w * 0.5, o.dy + h * 0.35, o.dx, o.dy)
        ..quadraticBezierTo(o.dx + w * 0.5, o.dy + h * 0.35, o.dx, o.dy + h)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    final leaf = Color.lerp(style.grass, const Color(0xFF43A047), 0.2)!;
    foliage(28 * scale, 20 * scale, base + Offset(0, -2 * scale), leaf);
    foliage(22 * scale, 16 * scale, base + Offset(-6 * scale, 6 * scale), Color.lerp(leaf, Colors.white, 0.2)!);
    foliage(20 * scale, 14 * scale, base + Offset(8 * scale, 10 * scale), Color.lerp(leaf, style.grass, 0.3)!);
  }

  void _drawFlower(Canvas canvas, Offset base, Color color) {
    canvas.drawLine(
      base,
      base + const Offset(0, 10),
      Paint()
        ..strokeWidth = 1.5
        ..color = const Color(0xFF558B2F),
    );
    canvas.drawCircle(base, 4.5, Paint()..color = color);
    canvas.drawCircle(base + const Offset(-3, 2), 3, Paint()..color = color.withValues(alpha: 0.85));
    canvas.drawCircle(base + const Offset(3, 2), 3, Paint()..color = color.withValues(alpha: 0.85));
  }

  void _drawCabin(Canvas canvas, Offset base, double scale) {
    final w = 34 * scale;
    final h = 26 * scale;
    final body = Rect.fromLTWH(base.dx - w * 0.5, base.dy - h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(3 * scale)),
      Paint()..color = const Color(0xFF8D6E63),
    );
    final roof = Path()
      ..moveTo(body.left - 4 * scale, body.top)
      ..lineTo(body.center.dx, body.top - 14 * scale)
      ..lineTo(body.right + 4 * scale, body.top)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5D4037));
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(body.center.dx, body.top + h * 0.55),
        width: 8 * scale,
        height: 10 * scale,
      ),
      Paint()..color = palette.glow.withValues(alpha: 0.7),
    );
  }

  void _drawWindmill(Canvas canvas, Offset base, double scale) {
    canvas.drawRect(
      Rect.fromCenter(center: base, width: 8 * scale, height: 28 * scale),
      Paint()..color = const Color(0xFFBCAAA4),
    );
    final angle = anim * 2 * math.pi;
    for (var i = 0; i < 4; i++) {
      final a = angle + i * math.pi / 2;
      canvas.drawLine(
        base + Offset(0, -14 * scale),
        base + Offset(math.cos(a) * 18 * scale, -14 * scale + math.sin(a) * 18 * scale),
        Paint()
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  void _drawRock(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.3, c.dy - r * 1.1, c.dx + r * 0.2, c.dy - r * 0.85)
      ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * 0.2, c.dx + r * 0.9, c.dy + r * 0.35)
      ..quadraticBezierTo(c.dx, c.dy + r, c.dx - r, c.dy);
    canvas.drawPath(
      path,
      Paint()..color = Color.lerp(const Color(0xFF78909C), const Color(0xFF546E7A), 0.5)!,
    );
  }

  Offset _extrude(Offset p, Offset center, double depth, double taper) {
    final v = p - center;
    return p + Offset(v.dx * taper * 0.12, depth);
  }

  @override
  bool shouldRepaint(covariant _GrowthIslandPainter old) {
    return old.style != style ||
        old.stage.level != stage.level ||
        old.anim != anim ||
        old.compact != compact ||
        old.visualStyle != visualStyle;
  }
}
