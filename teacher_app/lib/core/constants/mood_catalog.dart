import 'package:flutter/material.dart';

enum MoodFaceType { rad, good, meh, bad, awful }

class MoodOption {
  const MoodOption(this.id, this.label, this.color, this.faceType);
  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
}

const moods = <MoodOption>[
  MoodOption('happy', '超开心', Color(0xFF2A9D8F), MoodFaceType.rad),
  MoodOption('calm', '开心', Color(0xFF7CB342), MoodFaceType.good),
  MoodOption('thinking', '平静', Color(0xFF42A5F5), MoodFaceType.meh),
  MoodOption('sad', '低落', Color(0xFFFF9800), MoodFaceType.bad),
  MoodOption('angry', '生气', Color(0xFFEF5350), MoodFaceType.awful),
];

MoodOption moodById(String id) =>
    moods.firstWhere((m) => m.id == id, orElse: () => moods[2]);

String moodLabel(String id) => moodById(id).label;

Color moodColor(String id) => moodById(id).color;

String dominantMoodLabel(Map<String, int> counts) {
  if (counts.isEmpty) return '—';
  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  if (top.value <= 0) return '—';
  return moodLabel(top.key);
}

String concernBadge(String level) {
  switch (level) {
    case 'urgent':
      return '优先跟进';
    case 'watch':
      return '需关注';
    default:
      return '平稳';
  }
}

Color concernColor(String level) {
  switch (level) {
    case 'urgent':
      return const Color(0xFFE53935);
    case 'watch':
      return const Color(0xFFFF9800);
    default:
      return const Color(0xFF7CB342);
  }
}
