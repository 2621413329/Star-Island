import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/emotion_catalog.dart';
import 'package:stday/core/utils/mood_stats.dart';
import 'package:stday/data/models/profile_models.dart';

DailyMomentModel _moment({
  String emotionTag = 'calm',
  String? aiEmotion,
}) {
  return DailyMomentModel(
    id: 'm1',
    emotionTag: emotionTag,
    aiEmotion: aiEmotion,
    companionScene: 'default',
    companionPose: 'idle',
    createdAt: DateTime(2026, 6, 12),
    momentDate: DateTime(2026, 6, 12),
    eventTags: const ['学习'],
    visualPayload: const {},
  );
}

void main() {
  test('dominantMoodId picks highest count emotion', () {
    final counts = {
      'happy': 1,
      'kai_xin': 3,
      'calm': 2,
    };
    expect(dominantMoodId(counts), 'kai_xin');
  });

  test('effectiveEmotionForMoment prefers ai_emotion', () {
    final moment = _moment(emotionTag: 'calm', aiEmotion: '焦虑');
    expect(effectiveEmotionIdForMoment(moment), 'jiao_lv');
    expect(effectiveEmotionForMoment(moment).label, '焦虑');
  });

  test('unknown ai_emotion falls back to ping_jing', () {
    final moment = _moment(emotionTag: 'happy', aiEmotion: '随机词');
    expect(effectiveEmotionIdForMoment(moment), 'ping_jing');
    expect(effectiveEmotionForMoment(moment).label, '平静');
  });

  test('moodCountsForMoments aggregates extended emotions', () {
    final moments = [
      _moment(emotionTag: 'happy', aiEmotion: '开心'),
      _moment(emotionTag: 'calm', aiEmotion: '开心'),
      _moment(emotionTag: 'sad', aiEmotion: '失落'),
    ];
    final counts = moodCountsForMoments(moments);
    expect(counts['kai_xin'], 2);
    expect(counts['shi_luo'], 1);
    expect(dominantMoodId(counts), 'kai_xin');
  });

  test('legacyMoodCountsFromEmotionCounts rolls up for island atmosphere', () {
    final legacy = legacyMoodCountsFromEmotionCounts({
      'kai_xin': 2,
      'jiao_lv': 1,
      'fen_nu': 1,
    });
    expect(legacy['happy'], 2);
    expect(legacy['thinking'], 1);
    expect(legacy['angry'], 1);
  });
}
