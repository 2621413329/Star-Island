import '../constants/catalog.dart';
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
    moodScaleValues[moodId] ?? moodScaleValues['calm']!;

/// 将 [0, 1] 平均值映射到最近的一档心情。
String moodIdFromScaleAverage(double average) {
  var bestId = moods.first.id;
  var bestDistance = double.infinity;
  for (final mood in moods) {
    final value = moodScaleValues[mood.id];
    if (value == null) continue;
    final distance = (value - average).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestId = mood.id;
    }
  }
  return bestId;
}

/// 根据当日日常 emotion_tag 取 [0,1] 平均后映射主导心情。
String? averageMoodIdForMoments(List<DailyMomentModel> moments) {
  if (moments.isEmpty) return null;
  var sum = 0.0;
  var count = 0;
  for (final moment in moments) {
    final value = moodScaleValues[moment.emotionTag];
    if (value == null) continue;
    sum += value;
    count++;
  }
  if (count == 0) return moments.first.emotionTag;
  return moodIdFromScaleAverage(sum / count);
}

/// 按成长一级标签筛选 moment，统计五种心情出现次数。
Map<String, int> moodCountsForMoments(
  List<DailyMomentModel> moments, {
  String? categoryLabel,
}) {
  final counts = {for (final m in moods) m.id: 0};
  final filtered = categoryLabel == null
      ? moments
      : moments.where((m) => momentMatchesCategory(m, categoryLabel));
  for (final m in filtered) {
    if (counts.containsKey(m.emotionTag)) {
      counts[m.emotionTag] = counts[m.emotionTag]! + 1;
    }
  }
  return counts;
}

/// 雷达图视觉刻度：中心 -20%，外圈 100%（仅影响绘图，不改变真实占比）。
const moodRadarVisualMinPct = -20.0;
const moodRadarVisualMaxPct = 100.0;

/// 将占比 [0,1] 映射到半径系数 [0,1]，0% 落在内圈而非中心点。
double moodRadarRadiusFactor(double proportion) {
  final pct = proportion.clamp(0.0, 1.0) * moodRadarVisualMaxPct;
  return ((pct - moodRadarVisualMinPct) /
          (moodRadarVisualMaxPct - moodRadarVisualMinPct))
      .clamp(0.0, 1.0);
}

/// 将次数转为占比（0～1），与下方百分比条一致；绘图时用 [moodRadarRadiusFactor]。
Map<String, double> moodRadarScores(Map<String, int> counts) {
  final total = counts.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) {
    return {for (final m in moods) m.id: 0.0};
  }
  return {
    for (final m in moods)
      m.id: ((counts[m.id] ?? 0) / total).clamp(0.0, 1.0),
  };
}

int moodTotalForFilter(
  List<DailyMomentModel> moments, {
  String? categoryLabel,
}) {
  if (categoryLabel == null) return moments.length;
  return moments.where((m) => momentMatchesCategory(m, categoryLabel)).length;
}

/// 出现次数最多的心情 id；无记录时返回 null。
/// 若需按 0-1 均值推断今日心情，请用 [averageMoodIdForMoments]。
String? dominantMoodId(Map<String, int> counts) {
  final total = counts.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return null;
  var sum = 0.0;
  for (final mood in moods) {
    final count = counts[mood.id] ?? 0;
    sum += moodScaleValue(mood.id) * count;
  }
  return moodIdFromScaleAverage(sum / total);
}

class EventTagCount {
  const EventTagCount({required this.tagLabel, required this.count});

  final String tagLabel;
  final int count;
}

/// 按日常一级标签统计，返回 Top N。
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
