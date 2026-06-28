import 'package:flutter/material.dart';

import '../../../core/constants/island_weather.dart';
import '../../../core/weather/real_weather_snapshot.dart';
import 'mood_atmosphere_config.dart';

/// 将真实天气映射为岛屿氛围预设。
class WeatherAtmosphereConfig {
  WeatherAtmosphereConfig._();

  static IslandWeather weatherFromSnapshot(RealWeatherSnapshot weather) {
    final code = weather.weatherCode;
    if (weather.windSpeedKmh >= 40) return IslandWeather.windy;
    if (code == 0) {
      return weather.isDay ? IslandWeather.sunny : IslandWeather.softCloud;
    }
    if (code <= 3) return IslandWeather.softCloud;
    if (code == 45 || code == 48) return IslandWeather.overcast;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return IslandWeather.drizzle;
    }
    if (code >= 95) return IslandWeather.windy;
    if (code >= 71) return IslandWeather.overcast;
    return IslandWeather.softCloud;
  }

  static MoodAtmospherePreset fromSnapshot(RealWeatherSnapshot weather) {
    return _presetForWeather(weatherFromSnapshot(weather), weather.isDay);
  }

  /// 真实天气驱动天空/降水/风，心情保留波浪与色调微调。
  static MoodAtmospherePreset blendWithMood(
    RealWeatherSnapshot weather,
    MoodAtmospherePreset mood,
  ) {
    final base = fromSnapshot(weather);
    return MoodAtmospherePreset(
      skyTop: Color.lerp(mood.skyTop, base.skyTop, 0.72)!,
      skyBottom: Color.lerp(mood.skyBottom, base.skyBottom, 0.72)!,
      sunIntensity: base.sunIntensity,
      cloudDensity: base.cloudDensity,
      windStrength: base.windStrength,
      waveIntensity: (base.waveIntensity + mood.waveIntensity) / 2,
      particlePreset: base.particlePreset,
      rain: base.rain,
      lifePreset: base.lifePreset,
      fogOpacity: base.fogOpacity,
    );
  }

  static MoodAtmospherePreset _presetForWeather(
    IslandWeather kind,
    bool isDay,
  ) {
    return switch (kind) {
      IslandWeather.sunny => MoodAtmospherePreset(
          skyTop: const Color(0xFF87CEEB),
          skyBottom: const Color(0xFFFFF8E7),
          sunIntensity: isDay ? 1.15 : 0.35,
          cloudDensity: 0.08,
          windStrength: 0.12,
          waveIntensity: 0.42,
          particlePreset: isDay ? 'golden_sparkle' : 'starglow',
          rain: false,
          lifePreset: isDay ? 'seagulls' : 'starglow',
          fogOpacity: 0,
        ),
      IslandWeather.softCloud => MoodAtmospherePreset(
          skyTop: const Color(0xFFB8D4E8),
          skyBottom: const Color(0xFFE8F4FA),
          sunIntensity: isDay ? 0.78 : 0.28,
          cloudDensity: 0.38,
          windStrength: 0.18,
          waveIntensity: 0.34,
          particlePreset: 'bloom',
          rain: false,
          lifePreset: 'breeze',
          fogOpacity: 0.04,
        ),
      IslandWeather.overcast => const MoodAtmospherePreset(
          skyTop: Color(0xFF9EACB5),
          skyBottom: Color(0xFFDDE3E8),
          sunIntensity: 0.38,
          cloudDensity: 0.78,
          windStrength: 0.22,
          waveIntensity: 0.30,
          particlePreset: 'wind_leaves',
          rain: false,
          lifePreset: 'wind',
          fogOpacity: 0.18,
        ),
      IslandWeather.drizzle => const MoodAtmospherePreset(
          skyTop: Color(0xFF78909C),
          skyBottom: Color(0xFFB0BEC5),
          sunIntensity: 0.32,
          cloudDensity: 0.88,
          windStrength: 0.28,
          waveIntensity: 0.48,
          particlePreset: 'soft_rain',
          rain: true,
          lifePreset: 'drizzle',
          fogOpacity: 0.24,
        ),
      IslandWeather.windy => const MoodAtmospherePreset(
          skyTop: Color(0xFF90A4AE),
          skyBottom: Color(0xFFCFD8DC),
          sunIntensity: 0.52,
          cloudDensity: 0.62,
          windStrength: 0.88,
          waveIntensity: 0.56,
          particlePreset: 'wind_leaves',
          rain: false,
          lifePreset: 'wind',
          fogOpacity: 0.1,
        ),
    };
  }
}
