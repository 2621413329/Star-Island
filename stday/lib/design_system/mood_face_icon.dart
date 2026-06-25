import 'package:flutter/material.dart';

import '../core/constants/catalog.dart';
import '../core/utils/mood_face_paths.dart';
import 'mood_face_painter.dart';

/// 固定尺寸的心情表情；优先加载 [mood_faces] PNG，失败时用矢量绘制兜底。
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

    final candidates = moodFaceAssetCandidates(id, gender: gender);
    return SizedBox(
      width: size,
      height: size,
      child: _MoodFaceAssetImage(
        key: ValueKey('$id|${gender ?? ''}|${candidates.first}'),
        candidates: candidates,
        size: size,
        fallback: fallback,
      ),
    );
  }
}

class _MoodFaceAssetImage extends StatefulWidget {
  const _MoodFaceAssetImage({
    super.key,
    required this.candidates,
    required this.size,
    required this.fallback,
  });

  final List<String> candidates;
  final double size;
  final Widget fallback;

  @override
  State<_MoodFaceAssetImage> createState() => _MoodFaceAssetImageState();
}

class _MoodFaceAssetImageState extends State<_MoodFaceAssetImage> {
  var _index = 0;

  @override
  void didUpdateWidget(covariant _MoodFaceAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) return widget.fallback;
    final path = widget.candidates[_index];
    return Image.asset(
      path,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        if (_index + 1 < widget.candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index += 1);
          });
          return SizedBox(width: widget.size, height: widget.size);
        }
        return widget.fallback;
      },
    );
  }
}
