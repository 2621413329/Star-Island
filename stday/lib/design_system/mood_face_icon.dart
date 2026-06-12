import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import 'mood_face_asset_catalog.dart';
import 'mood_face_painter.dart';

/// 固定尺寸的心情表情；有 [moodId] 时优先加载 PNG，否则用矢量绘制兜底。
class MoodFaceIcon extends StatelessWidget {
  const MoodFaceIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 48,
    this.strokeWidth,
    this.moodId,
    this.gender,
  });

  final MoodFaceType type;
  final Color color;
  final double size;
  final double? strokeWidth;
  final String? moodId;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth ?? (size / 48 * 2.4).clamp(1.6, 2.8);
    final fallback = SizedBox(
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

    final id = moodId?.trim();
    if (id == null || id.isEmpty) return fallback;

    return FutureBuilder<MoodFaceAssetCatalog>(
      future: MoodFaceAssetCatalog.load(),
      builder: (context, snapshot) {
        final assetPath = snapshot.data?.resolve(id, gender: gender);
        if (assetPath == null) return fallback;
        return SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
          ),
        );
      },
    );
  }
}
