import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';
import 'healing_record_pencil_icon.dart';
import 'pressable_feedback.dart';

/// 果冻按钮配色：保留质感，色相跟随 [MoodPalette]。
class HealingJellyTone {
  const HealingJellyTone({
    required this.centerLight,
    required this.mid,
    required this.edge,
    required this.shadow,
    required this.bgTop,
    required this.bgBottom,
  });

  final Color centerLight;
  final Color mid;
  final Color edge;
  final Color shadow;
  final Color bgTop;
  final Color bgBottom;

  factory HealingJellyTone.fromPalette(MoodPalette palette) {
    final accent = palette.accent;
    return HealingJellyTone(
      centerLight: Color.lerp(accent, Colors.white, 0.82)!,
      mid: Color.lerp(accent, Colors.white, 0.38)!,
      edge: Color.lerp(accent, const Color(0xFF3D3229), 0.06)!,
      shadow: accent.withValues(alpha: 0.26),
      bgTop: Color.lerp(palette.gradientStart, Colors.white, 0.22)!,
      bgBottom: Color.lerp(palette.gradientStart, palette.gradientEnd, 0.35)!,
    );
  }
}

/// 极淡渐变底 + 四角星点氛围层。
class HealingSparkleBackground extends StatelessWidget {
  const HealingSparkleBackground({
    super.key,
    required this.child,
    required this.tone,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
  });

  final Widget child;
  final HealingJellyTone tone;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tone.bgTop, tone.bgBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HealingSparklePainter(borderRadius: borderRadius),
            ),
          ),
          if (padding != null)
            Padding(padding: padding!, child: child)
          else
            child,
        ],
      ),
    );
  }
}

class _HealingSparklePainter extends CustomPainter {
  const _HealingSparklePainter({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final stars = [
      Offset(size.width * 0.08, size.height * 0.12),
      Offset(size.width * 0.92, size.height * 0.10),
      Offset(size.width * 0.06, size.height * 0.88),
      Offset(size.width * 0.94, size.height * 0.86),
      Offset(size.width * 0.18, size.height * 0.06),
      Offset(size.width * 0.82, size.height * 0.92),
    ];
    for (var i = 0; i < stars.length; i++) {
      _drawSparkle(
          canvas, stars[i], 3.2 + (i % 2) * 1.2, 0.35 + (i % 3) * 0.12);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, double alpha) {
    final paint = Paint()
      ..color = const Color(0x99FFFFFF).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final outer = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final innerAngle = angle + math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(innerAngle) * radius * 0.28,
        center.dy + math.sin(innerAngle) * radius * 0.28,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HealingSparklePainter oldDelegate) => false;
}

/// 圆形果冻主按钮：铅笔图标 + 「开始记录」。
class HealingJellyCircleButton extends StatelessWidget {
  const HealingJellyCircleButton({
    super.key,
    required this.onPressed,
    required this.tone,
    this.size = 80,
    this.label = '开始记录',
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final HealingJellyTone tone;
  final double size;
  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: onPressed != null,
      child: PressableFeedback(
        onTap: onPressed,
        pressedScale: 0.94,
        feedback: PressFeedbackType.lightImpact,
        child: _JellyGlowWrapper(
          tone: tone,
          size: size,
          shape: BoxShape.circle,
          child: _JellySurface(
            tone: tone,
            size: Size(size, size),
            shape: BoxShape.circle,
            borderRadius: null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HealingRecordPencilIcon(size: size * 0.34),
                SizedBox(height: size * 0.05),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: appTextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆形图标果冻按钮（底部导航主 FAB 等）。
class HealingJellyIconButton extends StatelessWidget {
  const HealingJellyIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tone,
    this.size = 62,
    this.iconSize = 28,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final HealingJellyTone tone;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: PressableFeedback(
        onTap: onPressed,
        pressedScale: 0.94,
        feedback: PressFeedbackType.lightImpact,
        child: _JellyGlowWrapper(
          tone: tone,
          size: size,
          shape: BoxShape.circle,
          child: _JellySurface(
            tone: tone,
            size: Size(size, size),
            shape: BoxShape.circle,
            borderRadius: null,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

/// 胶囊形果冻主按钮（页面内主操作）。
class HealingJellyPillButton extends StatelessWidget {
  const HealingJellyPillButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.tone,
    this.icon,
    this.height = 48,
    this.minWidth = 120,
    this.expanded = false,
    this.semanticLabel,
    this.showGlow = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final HealingJellyTone tone;
  final IconData? icon;
  final double height;
  final double minWidth;
  final bool expanded;
  final String? semanticLabel;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    final content = PressableFeedback(
      onTap: onPressed,
      pressedScale: 0.97,
      feedback: PressFeedbackType.lightImpact,
      child: _JellyGlowWrapper(
        tone: tone,
        size: height,
        shape: BoxShape.rectangle,
        borderRadius: radius,
        enabled: showGlow,
        child: _JellySurface(
          tone: tone,
          size: Size(minWidth, height),
          shape: BoxShape.rectangle,
          borderRadius: radius,
          expandWidth: expanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: appTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, height: height, child: content);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
      child: content,
    );
  }
}

class _JellyGlowWrapper extends StatelessWidget {
  const _JellyGlowWrapper({
    required this.tone,
    required this.size,
    required this.shape,
    required this.child,
    this.borderRadius,
    this.enabled = true,
  });

  final HealingJellyTone tone;
  final double size;
  final BoxShape shape;
  final Widget child;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final decoration = shape == BoxShape.circle
        ? BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xCCFFFFFF).withValues(alpha: 0.75),
                blurRadius: 14,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: tone.shadow,
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xCCFFFFFF).withValues(alpha: 0.65),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: tone.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -3,
              ),
            ],
          );

    return DecoratedBox(decoration: decoration, child: child);
  }
}

class _JellySurface extends StatelessWidget {
  const _JellySurface({
    required this.tone,
    required this.size,
    required this.shape,
    required this.child,
    this.borderRadius,
    this.expandWidth = false,
  });

  final HealingJellyTone tone;
  final Size size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget child;
  final bool expandWidth;

  @override
  Widget build(BuildContext context) {
    final gradient = BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      gradient: RadialGradient(
        center: const Alignment(-0.12, -0.32),
        radius: 0.95,
        colors: [tone.centerLight, tone.mid, tone.edge],
        stops: const [0.0, 0.52, 1.0],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.72),
        width: 1.4,
      ),
    );

    return Container(
      width: expandWidth ? double.infinity : size.width,
      height: size.height,
      decoration: gradient,
      child: ClipRRect(
        borderRadius:
            borderRadius ?? BorderRadius.circular(size.shortestSide / 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, 0.55),
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

/// 包裹 [FilledButton] 的果冻渐变底。
class HealingJellyFilledButton extends StatelessWidget {
  const HealingJellyFilledButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.tone,
    this.icon,
    this.expanded = false,
    this.height = 48,
  });

  final VoidCallback? onPressed;
  final String label;
  final HealingJellyTone tone;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    return HealingJellyPillButton(
      onPressed: onPressed,
      label: label,
      tone: tone,
      icon: icon,
      height: height,
      expanded: expanded,
    );
  }
}
