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
    this.aiLabel,
  });

  final String id;
  final String label;
  final Color color;
  final MoodFaceType faceType;
  /// 岛屿氛围仍映射到内部 legacy id（用户不可见）。
  final String legacyMoodId;
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
    aiLabel: '开心',
  ),
  EmotionDefinition(
    id: 'ping_jing',
    label: '平静',
    color: Color(0xFF42A5F5),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'calm',
    aiLabel: '平静',
  ),
  EmotionDefinition(
    id: 'jiao_lv',
    label: '焦虑',
    color: Color(0xFF5C6BC0),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'thinking',
    aiLabel: '焦虑',
  ),
  EmotionDefinition(
    id: 'ya_li',
    label: '压力',
    color: Color(0xFF7E57C2),
    faceType: MoodFaceType.bad,
    legacyMoodId: 'thinking',
    aiLabel: '压力',
  ),
  EmotionDefinition(
    id: 'xing_fen',
    label: '兴奋',
    color: Color(0xFF26A69A),
    faceType: MoodFaceType.rad,
    legacyMoodId: 'happy',
    aiLabel: '兴奋',
  ),
  EmotionDefinition(
    id: 'gan_dong',
    label: '感动',
    color: Color(0xFF66BB6A),
    faceType: MoodFaceType.good,
    legacyMoodId: 'happy',
    aiLabel: '感动',
  ),
  EmotionDefinition(
    id: 'shi_luo',
    label: '失落',
    color: Color(0xFFFF9800),
    faceType: MoodFaceType.bad,
    legacyMoodId: 'sad',
    aiLabel: '失落',
  ),
  EmotionDefinition(
    id: 'fen_nu',
    label: '愤怒',
    color: Color(0xFFEF5350),
    faceType: MoodFaceType.awful,
    legacyMoodId: 'angry',
    aiLabel: '愤怒',
  ),
  EmotionDefinition(
    id: 'zi_wo_jue_cha',
    label: '自我觉察',
    color: Color(0xFF78909C),
    faceType: MoodFaceType.meh,
    legacyMoodId: 'thinking',
    aiLabel: '自我觉察',
  ),
  EmotionDefinition(
    id: 'shen_ti_guan_huai',
    label: '身体关怀',
    color: Color(0xFF8D6E63),
    faceType: MoodFaceType.good,
    legacyMoodId: 'calm',
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
  '伤心': 'shi_luo',
  '悲伤': 'shi_luo',
  '沮丧': 'shi_luo',
  '郁闷': 'shi_luo',
  '生气': 'fen_nu',
  '恼怒': 'fen_nu',
  '烦躁': 'fen_nu',
  '思考': 'jiao_lv',
  '担心': 'jiao_lv',
  '紧张': 'jiao_lv',
  '疲惫': 'ya_li',
  '累': 'ya_li',
  '疲倦': 'ya_li',
  '激动': 'xing_fen',
  '欣喜': 'kai_xin',
  '快乐': 'kai_xin',
  '愉快': 'kai_xin',
  '幸福': 'kai_xin',
  '欣慰': 'gan_dong',
  '感恩': 'gan_dong',
  '放松': 'ping_jing',
  '安宁': 'ping_jing',
  '淡定': 'ping_jing',
  '觉察': 'zi_wo_jue_cha',
  '反思': 'zi_wo_jue_cha',
  '身体不适': 'shen_ti_guan_huai',
  '生病': 'shen_ti_guan_huai',
};

int _charOverlapScore(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final charsB = b.split('');
  var score = 0;
  for (final char in a.split('')) {
    if (charsB.contains(char)) score++;
  }
  return score;
}

/// 将 AI 返回的中文感受映射到 10 档感受中最相近的一项（供小人/表情图使用）。
String closestCompanionEmotionIdFromAiLabel(String? raw) {
  final key = raw?.trim();
  if (key == null || key.isEmpty) return defaultEmotionId;
  if (_emotionById.containsKey(key)) return key;

  final fromSynonym = _aiLabelToEmotionId[key];
  if (fromSynonym != null) return fromSynonym;

  final fromLegacy = legacyTagToEmotionId[key];
  if (fromLegacy != null) return fromLegacy;

  for (final emotion in aiEmotions) {
    final label = emotion.label;
    if (key.contains(label) || label.contains(key)) return emotion.id;
  }
  for (final entry in _aiLabelToEmotionId.entries) {
    final synonym = entry.key;
    if (synonym.length >= 2 &&
        (key.contains(synonym) || synonym.contains(key))) {
      return entry.value;
    }
  }

  var bestId = defaultEmotionId;
  var bestScore = 0;
  for (final emotion in aiEmotions) {
    final score = _charOverlapScore(key, emotion.label);
    if (score > bestScore) {
      bestScore = score;
      bestId = emotion.id;
    }
  }
  for (final entry in _aiLabelToEmotionId.entries) {
    final score = _charOverlapScore(key, entry.key);
    if (score > bestScore) {
      bestScore = score;
      bestId = entry.value;
    }
  }
  return bestId;
}

/// 将任意历史 id / 中文标签规范为 AI 感受 id。
String normalizeEmotionId(String? raw) {
  final key = raw?.trim();
  if (key == null || key.isEmpty) return defaultEmotionId;
  if (_emotionById.containsKey(key)) return key;
  final fromLegacy = legacyTagToEmotionId[key];
  if (fromLegacy != null) return fromLegacy;
  final fromLabel = _aiLabelToEmotionId[key];
  if (fromLabel != null) return fromLabel;
  return closestCompanionEmotionIdFromAiLabel(key);
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

/// 小人/表情图/统计用的感受 id：AI 标签取 10 档中最相近项，否则映射旧 emotion_tag。
String companionEmotionIdForMoment(DailyMomentModel moment) {
  final aiLabel = _aiLabelFromMoment(moment);
  if (aiLabel != null) {
    return closestCompanionEmotionIdFromAiLabel(aiLabel);
  }
  return normalizeEmotionId(moment.emotionTag);
}

/// 日常有效心情（小人立绘、表情图、统计分组）。
EmotionDefinition effectiveEmotionForMoment(DailyMomentModel moment) =>
    emotionById(companionEmotionIdForMoment(moment));

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

/// 小人全身立绘资源 id（与 [mood_faces] 相同拼音 id）。
String effectiveCompanionExpressionForMoment(DailyMomentModel moment) =>
    effectiveEmotionIdForMoment(moment);

/// 选择与统计仅展示 AI 感受。
List<EmotionDefinition> emotionPickerCatalog() => aiEmotions;

List<EmotionDefinition> emotionStatsCatalog() => aiEmotions;

String emotionLabel(String id) => emotionById(id).label;

Color emotionColor(String id) => emotionById(id).color;

MoodFaceType emotionFaceType(String id) => emotionById(id).faceType;
