import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/moment_highlight.dart';
import 'package:stday/data/models/profile_models.dart';
import 'package:stday/providers/story_day_provider.dart';

DailyMomentModel _moment(DateTime day, String emotion, {DateTime? createdAt}) {
  return DailyMomentModel(
    id: 'm-${day.toIso8601String()}-$emotion',
    eventTags: const ['生活'],
    emotionTag: emotion,
    note: 'note',
    companionScene: 'idle',
    companionPose: 'breathing',
    visualPayload: const {},
    momentDate: day,
    createdAt: createdAt ?? day,
  );
}

void main() {
  test('pickHighlightMoment only uses today', () {
    final today = calendarDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final picked = pickHighlightMoment([
      _moment(yesterday, 'happy'),
      _moment(today, 'calm'),
    ]);
    expect(picked?.momentDate, today);
  });

  test('pickYesterdayMoment picks from yesterday only', () {
    final today = calendarDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final picked = pickYesterdayMoment([
      _moment(today, 'excited'),
      _moment(yesterday, 'calm'),
    ]);
    expect(picked?.momentDate, yesterday);
  });

  test('pickRandomOldMoment excludes today and yesterday', () {
    final today = calendarDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final older = today.subtract(const Duration(days: 3));
    final picked = pickRandomOldMoment([
      _moment(today, 'excited'),
      _moment(yesterday, 'happy'),
      _moment(older, 'calm'),
    ], seed: 'test');
    expect(calendarDate(picked!.momentDate), older);
  });
}
