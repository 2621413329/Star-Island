import '../../core/constants/island_weather.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../island/config/weather_atmosphere_config.dart';

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
