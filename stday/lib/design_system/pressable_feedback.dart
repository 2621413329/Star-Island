import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PressFeedbackType {
  none,
  selection,
  lightImpact,
  mediumImpact,
}

class PressableFeedback extends StatefulWidget {
  const PressableFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.feedback = PressFeedbackType.lightImpact,
    this.pressedScale = 0.96,
    this.selectedScale = 1,
    this.duration = const Duration(milliseconds: 140),
    this.curve = Curves.easeOutCubic,
    this.behavior = HitTestBehavior.opaque,
    this.inactiveOpacity = 0.62,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final PressFeedbackType feedback;
  final double pressedScale;
  final double selectedScale;
  final Duration duration;
  final Curve curve;
  final HitTestBehavior behavior;
  final double inactiveOpacity;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<PressableFeedback> createState() => _PressableFeedbackState();
}

class _PressableFeedbackState extends State<PressableFeedback> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _playFeedback() {
    switch (widget.feedback) {
      case PressFeedbackType.none:
        return;
      case PressFeedbackType.selection:
        HapticFeedback.selectionClick();
        return;
      case PressFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        return;
      case PressFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? widget.pressedScale : widget.selectedScale;
    final content = GestureDetector(
      behavior: widget.behavior,
      onTapDown: _active ? (_) => _setPressed(true) : null,
      onTapUp: _active
          ? (_) {
              _setPressed(false);
              _playFeedback();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedOpacity(
          opacity: _active ? (_pressed ? 0.88 : 1) : widget.inactiveOpacity,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      enabled: _active,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: content,
    );
  }
}
