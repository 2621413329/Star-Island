import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/config/day_phase_lighting_config.dart';

void main() {
  test('resolveDayPhase maps hours to morning, noon, evening', () {
    expect(resolveDayPhase(DateTime(2026, 6, 24, 7)), DayPhase.morning);
    expect(resolveDayPhase(DateTime(2026, 6, 24, 13)), DayPhase.noon);
    expect(resolveDayPhase(DateTime(2026, 6, 24, 18)), DayPhase.evening);
    expect(resolveDayPhase(DateTime(2026, 6, 24, 23)), DayPhase.evening);
  });

  test('day phase lighting presets differ in sun and shadow', () {
    final morning = DayPhaseLightingPreset.forPhase(DayPhase.morning);
    final noon = DayPhaseLightingPreset.forPhase(DayPhase.noon);
    final evening = DayPhaseLightingPreset.forPhase(DayPhase.evening);

    expect(morning.sunX, lessThan(noon.sunX));
    expect(evening.sunX, greaterThan(noon.sunX));
    expect(morning.shadowDx, greaterThan(0));
    expect(evening.shadowDx, lessThan(0));
    expect(noon.shadowStretch, lessThan(morning.shadowStretch));
  });
}
