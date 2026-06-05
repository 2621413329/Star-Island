import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import 'mood_face_painter.dart';

/// 固定尺寸的心情表情，避免 [CustomPaint] 在布局中坍缩为 0。
class MoodFaceIcon extends StatelessWidget {
  const MoodFaceIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 48,
    this.strokeWidth,
  });

  final MoodFaceType type;
  final Color color;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth ?? (size / 48 * 2.4).clamp(1.6, 2.8);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: MoodFacePainter(
          type: type,
          color: color,
          strokeWidth: stroke,
        ),
      ),
    );
  }
}
