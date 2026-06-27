import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/profile_models.dart';

DailyMomentModel _momentFromDate(dynamic momentDate) {
  return DailyMomentModel.fromJson({
    'id': 'm1',
    'event_tags': ['生活'],
    'emotion_tag': 'calm',
    'companion_scene': 'default',
    'moment_date': momentDate,
    'created_at': '2026-06-20T12:00:00Z',
  });
}

void main() {
  test('parses yyyy-MM-dd as local calendar date', () {
    final moment = _momentFromDate('2026-06-18');
    expect(moment.momentDate.year, 2026);
    expect(moment.momentDate.month, 6);
    expect(moment.momentDate.day, 18);
  });

  test('parses ISO datetime using local calendar day', () {
    final moment = _momentFromDate('2026-06-18T16:30:00.000Z');
    expect(moment.momentDate.day, 18);
  });
}
