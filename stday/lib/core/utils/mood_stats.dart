import '../constants/catalog.dart';
import '../constants/emotion_catalog.dart';
import '../../data/models/profile_models.dart';
import 'moment_tags.dart';

/// 五档心情在 [0, 1] 上的取值：生气=0，超开心=1。
const Map<String, double> moodScaleValues = {
  'angry': 0.0,
  'sad': 0.25,
  'thinking': 0.5,
  'calm': 0.75,
  'happy': 1.0,
};

double moodScaleValue(String moodId) =>
    moodScaleValues[emotionById(moodId).legacyMoodId] ??
    moodScaleValues['calm']!;

/// 将 [0, 1] 平均值映射到最近的一档内部 legacy 氛围 id。
String moodIdFromScaleAverage(double average) {
  var bestId = _legacyAtmosphereIds.first;
  var bestDistance = double.infinity;
  for (final moodId in _legacyAtmosphereIds) {
    final value = moodScaleValues[moodId];
    if (value == null) continue;
    final distance = (value - average).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestId = moodId;
    }
  }
  return bestId;
}

/// 根据当日日常有效心情取 [0,1] 平均后映射主导 legacy 氛围。
String? averageMoodIdForMoments(List<DailyMomentModel> moments) {
  if (moments.isEmpty) return null;
  var sum = 0.0;
  var count = 0;
  for (final moment in moments) {
    final legacy = effectiveLegacyMoodIdForMoment(moment);
    final value = moodScaleValues[legacy];
    if (value == null) continue;
    sum += value;
    count++;
  }
  if (count == 0) return effectiveLegacyMoodIdForMoment(moments.first);
  return moodIdFromScaleAverage(sum / count);
}

/// 按成长一级标签筛选 moment，统计扩展心情出现次数。
Map<String, int> moodCountsForMoments(
  List<DailyMomentModel> moments, {
  String? categoryLabel,
  String? emotionFilterId,
}) {
  final counts = {for (final e in emotionStatsCatalog()) e.id: 0};
  final filtered = categoryLabel == null
      ? moments
      : moments.where((m) => momentMatchesCategory(m, categoryLabel));
  for (final moment in filtered) {
    final emotionId = effectiveEmotionIdForMoment(moment);
    if (emotionFilterId != null && emotionId != emotionFilterId) continue;
    counts[emotionId] = (counts[emotionId] ?? 0) + 1;
  }
  return counts;
}

/// 将 AI 感受汇总到内部 legacy 五档（仅岛屿氛围，UI 不展示）。
const _legacyAtmosphereIds = ['happy', 'calm', 'thinking', 'sad', 'angry'];

Map<String, int> legacyMoodCountsFromEmotionCounts(Map<String, int> counts) {
  final legacy = {for (final id in _legacyAtmosphereIds) id: 0};
  counts.forEach((emotionId, count) {
    if (count <= 0) return;
    final legacyId = emotionById(emotionId).legacyMoodId;
    legacy[legacyId] = (legacy[legacyId] ?? 0) + count;
  });
  return legacy;
}

/// 雷达图视觉刻度：中心 -20%，外圈 100%（仅影响绘图，不改变真实占比）。
const moodRadarVisualMinPct = -20.0;
const moodRadarVisualMaxPct = 100.0;

double moodRadarRadiusFactor(double proportion) {
  final pct = proportion.clamp(0.0, 1.0) * moodRadarVisualMaxPct;
  return ((pct - moodRadarVisualMinPct) /
          (moodRadarVisualMaxPct - moodRadarVisualMinPct))
      .clamp(0.0, 1.0);
}

Map<String, double> moodRadarScores(Map<String, int> counts) {
  final legacyCounts = legacyMoodCountsFromEmotionCounts(counts);
  final total = legacyCounts.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) {
    return {for (final id in _legacyAtmosphereIds) id: 0.0};
  }
  return {
    for (final id in _legacyAtmosphereIds)
      id: ((legacyCounts[id] ?? 0) / total).clamp(0.0, 1.0),
  };
}

int moodTotalForFilter(
  List<DailyMomentModel> moments, {
  String? categoryLabel,
  String? emotionFilterId,
}) {
  final filtered = categoryLabel == null
      ? moments
      : moments.where((m) => momentMatchesCategory(m, categoryLabel));
  if (emotionFilterId == null) return filtered.length;
  return filtered
      .where((m) => effectiveEmotionIdForMoment(m) == emotionFilterId)
      .length;
}

/// 出现次数最多的心情 id；按占比（次数）而非 0-1 均值。
String? dominantMoodId(Map<String, int> counts) {
  String? bestId;
  var bestCount = -1;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      bestCount = entry.value;
      bestId = entry.key;
    }
  }
  return bestCount > 0 ? bestId : null;
}

/// 有记录的心情项，按次数降序。
List<EmotionDefinition> emotionEntriesWithCounts(Map<String, int> counts) {
  final entries = emotionStatsCatalog()
      .where((emotion) => (counts[emotion.id] ?? 0) > 0)
      .toList()
    ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
  return entries;
}

class EventTagCount {
  const EventTagCount({required this.tagLabel, required this.count});

  final String tagLabel;
  final int count;
}

List<EventTagCount> topEventTagsForMoments(
  List<DailyMomentModel> moments, {
  int limit = 3,
}) {
  final tallies = <String, int>{};
  for (final m in moments) {
    final label = momentPrimaryCategory(m);
    if (label == null) continue;
    tallies[label] = (tallies[label] ?? 0) + 1;
  }
  final sorted = tallies.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted
      .take(limit)
      .map((e) => EventTagCount(tagLabel: e.key, count: e.value))
      .toList();
}
