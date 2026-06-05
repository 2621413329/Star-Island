import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/mood_theme.dart';
import 'companion_loading.dart';

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
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? defaultPalette;
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _scale = 1.03),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _scale = 1);
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: p.primary, width: 1.5),
        foregroundColor: p.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: Text(label),
    );
  }
}
