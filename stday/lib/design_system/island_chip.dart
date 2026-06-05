import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';
import 'companion_loading.dart';
import 'pressable_feedback.dart';

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
  @override
  Widget build(BuildContext context) {
    return PressableFeedback(
      onTap: widget.onTap,
      feedback: PressFeedbackType.selection,
      pressedScale: 0.94,
      selectedScale: widget.selected ? 1.04 : 1,
      semanticLabel: widget.label,
      selected: widget.selected,
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
    );
  }
}

/// 次要操作：比主按钮矮，用于置顶条等场景。
class IslandCompactAction extends StatefulWidget {
  const IslandCompactAction({
    super.key,
    required this.label,
    required this.palette,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.highlight = false,
    this.height = 40,
    this.loadingMoodId,
  });

  final String label;
  final MoodPalette palette;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingMoodId;
  final bool enabled;
  final bool highlight;
  final double height;

  @override
  State<IslandCompactAction> createState() => _IslandCompactActionState();
}

class _IslandCompactActionState extends State<IslandCompactAction> {
  @override
  Widget build(BuildContext context) {
    final active =
        widget.enabled && !widget.loading && widget.onPressed != null;
    final useGradient = active && widget.highlight;

    return PressableFeedback(
      onTap: active ? widget.onPressed : null,
      pressedScale: 0.98,
      duration: const Duration(milliseconds: 120),
      inactiveOpacity: widget.loading ? 1 : 0.62,
      semanticLabel: widget.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: useGradient
              ? LinearGradient(
                  colors: [widget.palette.primary, widget.palette.accent],
                )
              : null,
          color: useGradient
              ? null
              : (active
                  ? widget.palette.card.withValues(alpha: 0.92)
                  : widget.palette.primaryContainer.withValues(alpha: 0.55)),
          border: Border.all(
            color: active
                ? widget.palette.accent.withValues(
                    alpha: widget.highlight ? 0.5 : 0.35,
                  )
                : widget.palette.accent.withValues(alpha: 0.2),
            width: widget.highlight && active ? 1.5 : 1,
          ),
          boxShadow: useGradient
              ? [
                  BoxShadow(
                    color: widget.palette.accent.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: widget.loading
            ? CompanionLoadingIndicator(
                palette: widget.palette,
                moodId: widget.loadingMoodId,
                size: 18,
                lightForeground: widget.highlight,
              )
            : Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: useGradient
                      ? Colors.white
                      : (active
                          ? widget.palette.accent
                          : const Color(0xFF8C7B6B)),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
    this.height = 52,
    this.loadingMoodId,
  });

  final String label;
  final VoidCallback? onPressed;
  final MoodPalette palette;
  final bool loading;
  final String? loadingMoodId;
  final bool enabled;
  final double height;

  @override
  State<IslandPrimaryAction> createState() => _IslandPrimaryActionState();
}

class _IslandPrimaryActionState extends State<IslandPrimaryAction> {
  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading && widget.onPressed != null;
    return PressableFeedback(
      onTap: active ? widget.onPressed : null,
      pressedScale: 0.96,
      inactiveOpacity: widget.loading ? 1 : 0.62,
      semanticLabel: widget.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
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
            ? CompanionLoadingIndicator(
                palette: widget.palette,
                moodId: widget.loadingMoodId,
                size: 20,
                lightForeground: true,
              )
            : Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.height <= 44 ? 15 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
