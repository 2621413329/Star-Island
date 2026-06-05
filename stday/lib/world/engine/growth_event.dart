import 'dart:ui';

import '../../core/models/character_mood.dart';
import '../../data/models/profile_models.dart';

enum GrowthEventType {
  reading,
  exercise,
  helpFriend,
  artCreate,
  family,
  hobby,
  social,
  other,
}

class GrowthEvent {
  const GrowthEvent({
    required this.id,
    required this.type,
    required this.mood,
    required this.occurredAt,
    this.expression = 'calm',
    this.prop = 'none',
    this.animationKey = 'wave',
    this.companionScene = 'stargaze',
    this.companionPose = 'breathing',
    this.tintHex,
    this.eventTags = const [],
    this.note,
  });

  final String id;
  final GrowthEventType type;
  final CharacterMood mood;
  final DateTime occurredAt;
  final String expression;
  final String prop;
  final String animationKey;
  final String companionScene;
  final String companionPose;
  final String? tintHex;
  final List<String> eventTags;
  final String? note;

  static GrowthEvent fromMoment(DailyMomentModel moment) {
    final spec = moment.companionSpec;
    return GrowthEvent(
      id: moment.id,
      type: inferType(moment.eventTags, moment.note, spec.prop),
      mood: CharacterMood.fromString(moment.emotionTag),
      occurredAt: DateTime.now(),
      expression: spec.expression,
      prop: spec.prop,
      animationKey: spec.animationType,
      companionScene: moment.companionScene,
      companionPose: moment.companionPose,
      tintHex: _tintToHex(spec.tint),
      eventTags: moment.eventTags,
      note: moment.note,
    );
  }

  static GrowthEventType inferType(
      List<String> tags, String? note, String prop) {
    final text = '${tags.join()} ${note ?? ''} $prop';
    if (RegExp(r'学习|读|书|作业|题|课|workbook|study').hasMatch(text)) {
      return GrowthEventType.reading;
    }
    if (RegExp(r'运动|跑|球|泳|sport|ball|badminton').hasMatch(text)) {
      return GrowthEventType.exercise;
    }
    if (RegExp(r'帮助|同学|朋友|friend|heart|chat').hasMatch(text)) {
      return GrowthEventType.helpFriend;
    }
    if (RegExp(r'画|艺术|创作|music|hobby').hasMatch(text)) {
      return GrowthEventType.artCreate;
    }
    if (RegExp(r'家|爸妈|父母|family|home').hasMatch(text)) {
      return GrowthEventType.family;
    }
    if (RegExp(r'兴趣|玩|hobby').hasMatch(text)) {
      return GrowthEventType.hobby;
    }
    if (RegExp(r'社交|聚会|social').hasMatch(text)) {
      return GrowthEventType.social;
    }
    return GrowthEventType.other;
  }

  static String? _tintToHex(dynamic tint) {
    if (tint is int) {
      return '#${(tint & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }
    if (tint is Color) {
      return '#${(tint.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }
    return null;
  }
}

class UserGrowthProfile {
  const UserGrowthProfile({
    this.todayMood = CharacterMood.calm,
    this.cumulativeCounts = const {},
    this.streakDays = const {},
    this.worldLevel = 1,
  });

  final CharacterMood todayMood;
  final Map<GrowthEventType, int> cumulativeCounts;
  final Map<GrowthEventType, int> streakDays;
  final int worldLevel;

  static UserGrowthProfile fromEvents(
      CharacterMood mood, List<GrowthEvent> events) {
    final counts = <GrowthEventType, int>{};
    for (final e in events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    return UserGrowthProfile(
      todayMood: mood,
      cumulativeCounts: counts,
      worldLevel: 1 + (counts.values.fold<int>(0, (a, b) => a + b) ~/ 5),
    );
  }
}
