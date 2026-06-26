import 'package:flutter/material.dart';

import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';

/// 小人头顶说话气泡。
class CompanionSpeechBubble extends StatelessWidget {
  const CompanionSpeechBubble({
    super.key,
    this.text,
    required this.palette,
    this.maxWidth = 220,
    this.tailTipInsetFromRight,
    this.showTail = true,
    this.child,
  }) : assert(text != null || child != null);

  final String? text;
  final MoodPalette palette;
  final double maxWidth;
  final bool showTail;
  final Widget? child;

  /// 尾巴尖端距气泡区域右边缘的距离；用于对准下方小人头部中心。
  final double? tailTipInsetFromRight;

  static const _tailWidth = 18.0;
  static const _tailHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    final borderColor = palette.accent.withValues(alpha: 0.35);
    final fillColor = palette.card.withValues(alpha: 0.98);
    final tailRightPadding = tailTipInsetFromRight == null
        ? null
        : (tailTipInsetFromRight! - _tailWidth / 2)
            .clamp(0.0, double.infinity);

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child ??
                Text(
                  text!,
                  softWrap: true,
                  style: appTextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A3F36),
                  ),
                ),
          ),
          if (showTail)
            if (tailRightPadding == null)
              CustomPaint(
                size: const Size(_tailWidth, _tailHeight),
                painter: _BubbleTailPainter(color: fillColor, borderColor: borderColor),
              )
            else
              Padding(
                padding: EdgeInsets.only(right: tailRightPadding),
                child: CustomPaint(
                  size: const Size(_tailWidth, _tailHeight),
                  painter: _BubbleTailPainter(
                    color: fillColor,
                    borderColor: borderColor,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
