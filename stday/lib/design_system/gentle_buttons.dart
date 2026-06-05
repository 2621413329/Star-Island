import 'package:flutter/material.dart';

import '../core/theme/mood_theme.dart';
import 'companion_loading.dart';
import 'pressable_feedback.dart';

class GentlePrimaryButton extends StatefulWidget {
  const GentlePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.palette,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final MoodPalette? palette;

  @override
  State<GentlePrimaryButton> createState() => _GentlePrimaryButtonState();
}

class _GentlePrimaryButtonState extends State<GentlePrimaryButton> {
  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? defaultPalette;
    final active = !widget.loading && widget.onPressed != null;
    return PressableFeedback(
      onTap: active ? widget.onPressed : null,
      pressedScale: 0.97,
      inactiveOpacity: widget.loading ? 1 : 0.62,
      semanticLabel: widget.label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: palette.primary,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: widget.loading
              ? CompanionLoadingIndicator(
                  palette: palette,
                  size: 20,
                  lightForeground: true,
                )
              : Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class GentleSecondaryButton extends StatelessWidget {
  const GentleSecondaryButton({super.key, required this.label, required this.onPressed, this.palette});

  final String label;
  final VoidCallback onPressed;
  final MoodPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? defaultPalette;
    return PressableFeedback(
      onTap: onPressed,
      pressedScale: 0.97,
      semanticLabel: label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: p.primary,
            side: BorderSide(color: p.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
