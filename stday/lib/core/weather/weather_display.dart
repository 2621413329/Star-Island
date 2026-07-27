import '../../core/constants/island_weather.dart';
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
/// 仅返回真实城市名；加载中/失败时返回空，避免「当前位置」占位。
String weatherLocationLabelFromSnapshot(RealWeatherSnapshot? weather) {
  return weatherPlaceLabelFromSnapshot(weather) ?? '';
}

/// 顶部卡片用：未授权/默认坐标时不占位，由 UI 回退为「成长世界」。
/// 已拿到真实定位但反查失败时也不再显示「当前位置」占位文案。
String? weatherPlaceLabelFromSnapshot(RealWeatherSnapshot? weather) {
  if (weather == null) return null;
  if (weather.usedFallbackCoordinates) return null;
  final name = weather.locationName?.trim();
  if (name == null || name.isEmpty) return null;
  if (name == '当前位置' || name == '定位中…' || name == '成长世界') {
    return null;
  }
  return name;
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
