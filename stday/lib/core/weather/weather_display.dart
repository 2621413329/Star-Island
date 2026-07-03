import '../../core/constants/island_weather.dart';
import '../../core/weather/island_weather_service.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../world/systems/config/weather_atmosphere_config.dart';

/// 将 Open-Meteo 快照转为展示用语义。
IslandWeather islandWeatherKind(RealWeatherSnapshot? weather) {
  if (weather == null) return IslandWeather.softCloud;
  return WeatherAtmosphereConfig.weatherFromSnapshot(weather);
}

String weatherDisplayLabel(IslandWeather kind, {bool isDay = true}) {
  return switch (kind) {
    IslandWeather.sunny => isDay ? '晴朗' : '晴夜',
    IslandWeather.softCloud => '多云',
    IslandWeather.overcast => '阴天',
    IslandWeather.drizzle => '小雨',
    IslandWeather.windy => '有风',
  };
}

String weatherDisplayLabelFromSnapshot(RealWeatherSnapshot? weather) {
  if (weather == null) return '获取中';
  return weatherDisplayLabel(
    islandWeatherKind(weather),
    isDay: weather.isDay,
  );
}

/// 天气数据来源的所在地展示文案（详情 HUD 等）。
String weatherLocationLabelFromSnapshot(RealWeatherSnapshot? weather) {
  final place = weatherPlaceLabelFromSnapshot(weather);
  if (place != null) return place;
  if (weather == null) return '定位中…';
  return '';
}

/// 顶部卡片用：未授权/默认坐标时不占位，由 UI 回退为「成长世界」。
String? weatherPlaceLabelFromSnapshot(RealWeatherSnapshot? weather) {
  if (weather == null) return null;
  if (_usesDefaultCoordinates(weather)) return null;
  final name = weather.locationName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return '当前位置';
}

String weatherCardLocationLine({
  required RealWeatherSnapshot? weather,
  required String weatherLabel,
}) {
  final place = weatherPlaceLabelFromSnapshot(weather)?.trim() ?? '';
  final weatherText = weatherLabel.isEmpty ? '多云' : weatherLabel;
  if (place.isEmpty) return '成长世界 · $weatherText';
  return '$place · $weatherText';
}

bool _usesDefaultCoordinates(RealWeatherSnapshot weather) {
  final lat = weather.latitude;
  final lng = weather.longitude;
  if (lat == null || lng == null) return false;
  const eps = 0.02;
  return (lat - IslandWeatherService.defaultLatitude).abs() < eps &&
      (lng - IslandWeatherService.defaultLongitude).abs() < eps;
}
