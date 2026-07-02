import '../../data/models/profile_models.dart';
import '../../providers/story_day_provider.dart';
import '../constants/emotion_catalog.dart';

/// 情绪高涨程度（越大越优先展示）。
int emotionValenceScore(String emotionId) {
  return switch (normalizeEmotionId(emotionId)) {
    'xing_fen' => 100,
    'kai_xin' => 90,
    'gan_dong' => 80,
    'ping_jing' => 50,
    'jiao_lv' => 30,
    'ya_li' => 20,
    'shi_luo' => 10,
    'fen_nu' => 0,
    _ => 40,
  };
}

int momentValenceScore(DailyMomentModel moment) =>
    emotionValenceScore(companionEmotionIdForMoment(moment));

bool isSameMomentDay(DateTime a, DateTime b) =>
    calendarDate(a) == calendarDate(b);

/// 今日最值得展示的一条日常：优先情绪高涨，其次最新。
DailyMomentModel? pickHighlightMoment(Iterable<DailyMomentModel> moments) {
  final today = calendarDate(DateTime.now());
  return _pickBestMoment(
    moments.where((m) => isSameMomentDay(m.momentDate, today)),
  );
}

/// 昨日固定一条：优先情绪更高，其次更新。
DailyMomentModel? pickYesterdayMoment(Iterable<DailyMomentModel> moments) {
  final yesterday = calendarDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );
  return _pickBestMoment(
    moments.where((m) => isSameMomentDay(m.momentDate, yesterday)),
  );
}

/// 更早随机一条：排除今/昨，稳定随机（按用户+日期种子）。
DailyMomentModel? pickRandomOldMoment(
  Iterable<DailyMomentModel> moments, {
  String? seed,
}) {
  final today = calendarDate(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));
  final older = moments.where((m) {
    final day = calendarDate(m.momentDate);
    return day != today && day != yesterday;
  }).toList();
  if (older.isEmpty) return null;
  final basis = seed ?? '${today.toIso8601String()}_${older.length}';
  final index = basis.hashCode.abs() % older.length;
  return older[index];
}

DailyMomentModel? _pickBestMoment(Iterable<DailyMomentModel> moments) {
  DailyMomentModel? best;
  var bestScore = -1;
  for (final moment in moments) {
    final score = momentValenceScore(moment);
    if (best == null ||
        score > bestScore ||
        (score == bestScore && moment.createdAt.isAfter(best.createdAt))) {
      best = moment;
      bestScore = score;
    }
  }
  return best;
}
