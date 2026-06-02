import 'package:flutter/material.dart';

class MoodOption {
  const MoodOption(this.id, this.label, this.color, this.faceType);
  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
}

enum MoodFaceType { rad, good, meh, bad, awful }

const moods = <MoodOption>[
  MoodOption('happy', '超开心', Color(0xFF2A9D8F), MoodFaceType.rad),
  MoodOption('calm', '开心', Color(0xFF7CB342), MoodFaceType.good),
  MoodOption('thinking', '平静', Color(0xFF42A5F5), MoodFaceType.meh),
  MoodOption('sad', '低落', Color(0xFFFF9800), MoodFaceType.bad),
  MoodOption('angry', '生气', Color(0xFFEF5350), MoodFaceType.awful),
];

class EventTagOption {
  const EventTagOption(this.id, this.emoji, this.label, this.storyLabel);
  final String id;
  final String emoji;
  final String label;
  final String storyLabel;
}

const eventTags = <EventTagOption>[
  EventTagOption('学习', '📚', '学习', '学习故事'),
  EventTagOption('朋友', '👫', '朋友', '友谊故事'),
  EventTagOption('运动', '🏃', '运动', '运动故事'),
  EventTagOption('家庭', '🏠', '家庭', '家庭故事'),
  EventTagOption('兴趣', '🎨', '兴趣', '兴趣故事'),
  EventTagOption('其它', '✨', '其它', '今日故事'),
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

String primaryStoryLabel(List<String> tags) {
  if (tags.isEmpty) return '今日故事';
  final tag = tags.first;
  return eventTags.firstWhere((e) => e.id == tag, orElse: () => eventTags.last).storyLabel;
}
