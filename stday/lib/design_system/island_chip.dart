import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/mood_theme.dart';

class IslandChip extends StatefulWidget {
  const IslandChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.emoji,
  });

  final String label;
  final String? emoji;
  final bool selected;
  final VoidCallback onTap;
  final MoodPalette palette;

  @override
  State<IslandChip> createState() => _IslandChipState();
}

class _IslandChipState extends State<IslandChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : (widget.selected ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.selected ? widget.palette.primaryContainer : widget.palette.card,
            border: Border.all(
              color: widget.selected ? widget.palette.accent : Colors.white.withValues(alpha: 0.8),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [BoxShadow(color: widget.palette.accent.withValues(alpha: 0.2), blurRadius: 12)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.emoji != null) Text(widget.emoji!, style: const TextStyle(fontSize: 18)),
              if (widget.emoji != null) const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF3D3229),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IslandPrimaryAction extends StatefulWidget {
  const IslandPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.palette,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MoodPalette palette;
  final bool loading;
  final bool enabled;

  @override
  State<IslandPrimaryAction> createState() => _IslandPrimaryActionState();
}

class _IslandPrimaryActionState extends State<IslandPrimaryAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading && widget.onPressed != null;
    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: active
                  ? [widget.palette.primary, widget.palette.accent]
                  : [Colors.grey.shade300, Colors.grey.shade400],
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: widget.palette.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
