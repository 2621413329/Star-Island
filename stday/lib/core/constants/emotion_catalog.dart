import 'package:flutter/material.dart';

import '../../data/models/profile_models.dart';
import 'mood_types.dart';

/// 资源替换说明见 [assets/images/mood_faces/README.md]。
class EmotionDefinition {
  const EmotionDefinition({
    required this.id,
    required this.label,
    required this.color,
    required this.faceType,
    required this.legacyMoodId,
    required this.companionExpression,
    this.aiLabel,
  });

  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
  /// 岛屿氛围仍映射到内部 legacy id（用户不可见）。
  final String legacyMoodId;
  final String companionExpression;
  final String? aiLabel;
}

const emotionPlaceholderAssetId = '_placeholder';
const defaultEmotionId = 'ping_jing';

/// 旧五档 emotion_tag → AI 感受 id（仅兼容历史数据）。
const legacyTagToEmotionId = <String, String>{
  'happy': 'kai_xin',
  'calm': 'ping_jing',
  'thinking': 'jiao_lv',
  'sad': 'shi_luo',
  'angry': 'fen_nu',
};

const aiEmotions = <EmotionDefinition>[
  EmotionDefinition(
    id: 'kai_xin',
    label: '开心',
    color: Color(0xFF2A9D8F),
    faceType: MoodFaceType.rad,
    legacyMoodId: 'happy',
    companionExpression: 'happy',
    aiLabel: '开心',
  ),
  EmotionDefinition(
    id: 'ping_jing',
    label: '平静',
    color: Color(0xFF42A5F5),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'calm',
    companionExpression: 'calm',
    aiLabel: '平静',
  ),
  EmotionDefinition(
    id: 'jiao_lv',
    label: '焦虑',
    color: Color(0xFF5C6BC0),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'thinking',
    companionExpression: 'thinking',
    aiLabel: '焦虑',
  ),
  EmotionDefinition(
    id: 'ya_li',
    label: '压力',
    color: Color(0xFF7E57C2),
    faceType: MoodFaceType.bad,
    legacyMoodId: 'thinking',
    companionExpression: 'thinking',
    aiLabel: '压力',
  ),
  EmotionDefinition(
    id: 'xing_fen',
    label: '兴奋',
    color: Color(0xFF26A69A),
    faceType: MoodFaceType.rad,
    legacyMoodId: 'happy',
    companionExpression: 'happy',
    aiLabel: '兴奋',
  ),
  EmotionDefinition(
    id: 'gan_dong',
    label: '感动',
    color: Color(0xFF66BB6A),
    faceType: MoodFaceType.good,
    legacyMoodId: 'happy',
    companionExpression: 'hopeful',
    aiLabel: '感动',
  ),
  EmotionDefinition(
    id: 'shi_luo',
    label: '失落',
    color: Color(0xFFFF9800),
    faceType: MoodFaceType.bad,
    legacyMoodId: 'sad',
    companionExpression: 'sad',
    aiLabel: '失落',
  ),
  EmotionDefinition(
    id: 'fen_nu',
    label: '愤怒',
    color: Color(0xFFEF5350),
    faceType: MoodFaceType.awful,
    legacyMoodId: 'angry',
    companionExpression: 'angry',
    aiLabel: '愤怒',
  ),
  EmotionDefinition(
    id: 'zi_wo_jue_cha',
    label: '自我觉察',
    color: Color(0xFF78909C),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'thinking',
    companionExpression: 'thinking',
    aiLabel: '自我觉察',
  ),
  EmotionDefinition(
    id: 'shen_ti_guan_huai',
    label: '身体关怀',
    color: Color(0xFF8D6E63),
    faceType: MoodFaceType.good,
    legacyMoodId: 'calm',
    companionExpression: 'hopeful',
    aiLabel: '身体关怀',
  ),
];

final Map<String, EmotionDefinition> _emotionById = {
  for (final emotion in aiEmotions) emotion.id: emotion,
};

final Map<String, String> _aiLabelToEmotionId = {
  for (final emotion in aiEmotions)
    if (emotion.aiLabel != null) emotion.aiLabel!: emotion.id,
  '满足': 'kai_xin',
  '难过': 'shi_luo',
  '生气': 'fen_nu',
  '思考': 'jiao_lv',
};

/// 将任意历史 id / 中文标签规范为 AI 感受 id。
String normalizeEmotionId(String? raw) {
  final key = raw?.trim();
  if (key == null || key.isEmpty) return defaultEmotionId;
  if (_emotionById.containsKey(key)) return key;
  final fromLegacy = legacyTagToEmotionId[key];
  if (fromLegacy != null) return fromLegacy;
  final fromLabel = _aiLabelToEmotionId[key];
  if (fromLabel != null) return fromLabel;
  return defaultEmotionId;
}

EmotionDefinition emotionById(String? id) =>
    _emotionById[normalizeEmotionId(id)]!;

EmotionDefinition? emotionByAiLabel(String? label) {
  final key = label?.trim();
  if (key == null || key.isEmpty) return null;
  final id = _aiLabelToEmotionId[key];
  if (id == null) return null;
  return _emotionById[id];
}

/// 日常有效心情：优先 AI 感受，否则将旧 emotion_tag 映射为 AI 感受。
EmotionDefinition effectiveEmotionForMoment(DailyMomentModel moment) {
  final fromAi = emotionByAiLabel(_aiLabelFromMoment(moment));
  if (fromAi != null) return fromAi;
  return emotionById(moment.emotionTag);
}

String? _aiLabelFromMoment(DailyMomentModel moment) {
  final ai = moment.aiEmotion?.trim();
  if (ai != null && ai.isNotEmpty) return ai;
  final fromPayload = moment.visualPayload['ai_emotion'];
  if (fromPayload is String && fromPayload.trim().isNotEmpty) {
    return fromPayload.trim();
  }
  return null;
}

String effectiveEmotionIdForMoment(DailyMomentModel moment) =>
    effectiveEmotionForMoment(moment).id;

String effectiveLegacyMoodIdForMoment(DailyMomentModel moment) =>
    effectiveEmotionForMoment(moment).legacyMoodId;

String effectiveCompanionExpressionForMoment(DailyMomentModel moment) =>
    effectiveEmotionForMoment(moment).companionExpression;

/// 选择与统计仅展示 AI 感受。
List<EmotionDefinition> emotionPickerCatalog() => aiEmotions;

List<EmotionDefinition> emotionStatsCatalog() => aiEmotions;

String emotionLabel(String id) => emotionById(id).label;

Color emotionColor(String id) => emotionById(id).color;

MoodFaceType emotionFaceType(String id) => emotionById(id).faceType;
