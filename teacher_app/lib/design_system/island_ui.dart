import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/mood_theme.dart';

class IslandScaffold extends StatelessWidget {
  const IslandScaffold({super.key, required this.palette, required this.child});

  final MoodPalette palette;
  final Widget child;

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
          Positioned(
            top: -40,
            right: -30,
            child: _Orb(color: palette.glow.withValues(alpha: 0.55), size: 180),
          ),
          Positioned(
            bottom: 80,
            left: -20,
            child: _Orb(color: palette.primary.withValues(alpha: 0.2), size: 120),
          ),
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
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: palette.card.withValues(alpha: 0.92),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class IslandPrimaryAction extends StatelessWidget {
  const IslandPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.palette,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final MoodPalette palette;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final active = !loading && onPressed != null;
    return GestureDetector(
      onTap: active
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: active
                ? [palette.primary, palette.accent]
                : [Colors.grey.shade300, Colors.grey.shade400],
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class IslandChipToggle extends StatelessWidget {
  const IslandChipToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final MoodPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 14 : 20),
          color: selected ? palette.primary : palette.card,
          border: Border.all(
            color: selected ? palette.accent : palette.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF3D3229),
          ),
        ),
      ),
    );
  }
}
