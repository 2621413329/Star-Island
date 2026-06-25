import 'package:flutter/material.dart';

/// 每日心情 · 表情插图目录：`assets/images/mood_faces/`
const moodFaceAssetDir = 'assets/images/mood_faces';

class MoodOption {
  const MoodOption(
    this.id,
    this.label,
    this.color,
    this.faceType, {
    this.asset,
  });

  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
  final String? asset;
}

enum MoodFaceType { rad, good, meh, bad, awful }
