import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';

class IslandScaffold extends StatelessWidget {
  const IslandScaffold({
    super.key,
    required this.palette,
    required this.child,
    this.showOrbs = true,
  });

  final MoodPalette palette;
  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.gradientStart, palette.gradientEnd, palette.primaryContainer],
        ),
      ),
      child: Stack(
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -40,
              right: -30,
              child: _Orb(color: palette.glow.withValues(alpha: 0.55), size: 180),
            ),
            Positioned(
              top: 120,
              left: -50,
              child: _Orb(color: palette.accent.withValues(alpha: 0.25), size: 140),
            ),
            Positioned(
              bottom: 80,
              right: 20,
              child: _Orb(color: palette.primary.withValues(alpha: 0.18), size: 100),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class IslandGlassCard extends StatelessWidget {
  const IslandGlassCard({super.key, required this.palette, required this.child, this.padding});

  final MoodPalette palette;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.card.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
