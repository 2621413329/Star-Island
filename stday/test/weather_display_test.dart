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
      usedFallbackCoordinates: true,
    );
    expect(
      weatherCardLocationLine(weather: weather, weatherLabel: '多云'),
      '成长世界 · 多云',
    );
    expect(weatherLocationLabelFromSnapshot(weather), '');
    expect(weatherLocationLabelFromSnapshot(null), '');
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

  test('weatherPlaceLabelFromSnapshot hides placeholder 当前位置', () {
    final weather = RealWeatherSnapshot(
      weatherCode: 0,
      windSpeedKmh: 0,
      isDay: true,
      fetchedAt: DateTime(2026, 1, 1),
      latitude: 39.9,
      longitude: 116.4,
      locationName: '当前位置',
    );
    expect(weatherPlaceLabelFromSnapshot(weather), isNull);
    expect(
      weatherCardLocationLine(weather: weather, weatherLabel: '晴朗'),
      '成长世界 · 晴朗',
    );
  });

  test('real Shanghai coords still show city when not fallback', () {
    final weather = RealWeatherSnapshot(
      weatherCode: 0,
      windSpeedKmh: 0,
      isDay: true,
      fetchedAt: DateTime(2026, 1, 1),
      latitude: IslandWeatherService.defaultLatitude,
      longitude: IslandWeatherService.defaultLongitude,
      locationName: '上海市 · 黄浦区',
      usedFallbackCoordinates: false,
    );
    expect(weatherPlaceLabelFromSnapshot(weather), '上海市 · 黄浦区');
  });
}
