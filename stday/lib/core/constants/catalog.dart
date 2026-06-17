import 'package:flutter/material.dart';

/// 每日心情 · 表情插图目录：`assets/images/mood_faces/`
/// 通用文件名：`<moodId>.png`；按性别：`man_<moodId>.png` / `woman_<moodId>.png`。
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

const moods = <MoodOption>[
  MoodOption(
    'happy',
    '超开心',
    Color(0xFF2A9D8F),
    MoodFaceType.rad,
    asset: '$moodFaceAssetDir/happy.png',
  ),
  MoodOption(
    'calm',
    '开心',
    Color(0xFF7CB342),
    MoodFaceType.good,
    asset: '$moodFaceAssetDir/calm.png',
  ),
  MoodOption(
    'thinking',
    '平静',
    Color(0xFF42A5F5),
    MoodFaceType.meh,
    asset: '$moodFaceAssetDir/thinking.png',
  ),
  MoodOption(
    'sad',
    '低落',
    Color(0xFFFF9800),
    MoodFaceType.bad,
    asset: '$moodFaceAssetDir/sad.png',
  ),
  MoodOption(
    'angry',
    '生气',
    Color(0xFFEF5350),
    MoodFaceType.awful,
    asset: '$moodFaceAssetDir/angry.png',
  ),
];

const welcomeLines = [
  '欢迎回来',
  '今天也辛苦啦',
  '今天有什么想记录的吗',
];

const defaultWaitingLines = [
  '小星正在轻轻醒来…',
  '把你的故事织进风里',
  '马上来见你啦',
];

MoodOption moodById(String id) =>
    moods.firstWhere((m) => m.id == id, orElse: () => moods[2]);

String moodLabel(String id) => moodById(id).label;

Color moodColor(String id) => moodById(id).color;
