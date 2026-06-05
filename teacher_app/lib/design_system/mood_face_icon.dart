import 'package:flutter/material.dart';

import '../core/constants/mood_catalog.dart';
import 'mood_face_painter.dart';

class MoodFaceIcon extends StatelessWidget {
  const MoodFaceIcon({
    super.key,
    required this.moodId,
    this.size = 36,
  });

  final String moodId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = moodById(moodId);
    final stroke = (size / 48 * 2.4).clamp(1.6, 2.8);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: MoodFacePainter(
          type: m.faceType,
          color: m.color,
          strokeWidth: stroke,
        ),
      ),
    );
  }
}
