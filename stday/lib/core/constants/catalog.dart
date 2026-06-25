import 'package:flutter/material.dart';

import 'emotion_catalog.dart';
import 'mood_types.dart';

export 'mood_types.dart' show MoodFaceType, MoodOption, moodFaceAssetDir;

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
