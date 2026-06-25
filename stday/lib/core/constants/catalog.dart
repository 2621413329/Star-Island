import 'package:flutter/material.dart';

import 'emotion_catalog.dart';

/// 每日心情 · 表情插图目录：`assets/images/mood_faces/`
/// 通用文件名：`<emotionId>.png`；按性别：`man_<emotionId>.png` / `woman_<emotionId>.png`。
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

/// 用户可见的心情列表（仅 AI 感受）。
List<MoodOption> get moods => aiEmotions
    .map(
      (e) => MoodOption(
        e.id,
        e.label,
        e.color,
        e.faceType,
        asset: '$moodFaceAssetDir/${e.id}.png',
      ),
    )
    .toList();

const welcomeLines = [
  '欢迎回来',
  '今天也辛苦啦',
  '今天有什么想记录的吗',
];

const defaultWaitingLines = [
  '小星正在轻轻醒来…',
  '把你的日常织进风里',
  '马上来见你啦',
];

MoodOption moodById(String id) {
  final emotion = emotionById(id);
  return MoodOption(
    emotion.id,
    emotion.label,
    emotion.color,
    emotion.faceType,
    asset: '$moodFaceAssetDir/${emotion.id}.png',
  );
}

String moodLabel(String id) => emotionLabel(id);

Color moodColor(String id) => emotionColor(id);
