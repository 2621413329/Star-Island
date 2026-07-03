import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/weather/island_weather_service.dart';
import 'package:stday/core/weather/real_weather_snapshot.dart';
import 'package:stday/core/weather/weather_display.dart';

void main() {
  test('weatherCardLocationLine falls back to 成长世界 when unauthorized', () {
    final weather = RealWeatherSnapshot(
      weatherCode: 0,
      windSpeedKmh: 0,
      isDay: true,
      fetchedAt: DateTime(2026, 1, 1),
      latitude: IslandWeatherService.defaultLatitude,
      longitude: IslandWeatherService.defaultLongitude,
    );
    expect(
      weatherCardLocationLine(weather: weather, weatherLabel: '多云'),
      '成长世界 · 多云',
    );
    expect(weatherLocationLabelFromSnapshot(weather), '');
  });

  test('weatherCardLocationLine shows city when available', () {
    final weather = RealWeatherSnapshot(
      weatherCode: 0,
      windSpeedKmh: 0,
      isDay: true,
      fetchedAt: DateTime(2026, 1, 1),
      latitude: 39.9,
      longitude: 116.4,
      locationName: '北京 · 朝阳',
    );
    expect(
      weatherCardLocationLine(weather: weather, weatherLabel: '晴朗'),
      '北京 · 朝阳 · 晴朗',
    );
  });
}
