import '../../core/models/mood_island_config.dart';
import '../../core/weather/real_weather_snapshot.dart';
import '../../island/config/island_visual_config.dart';
import '../../island/config/mood_atmosphere_config.dart';
import '../../island/config/weather_atmosphere_config.dart';

/// 合并固定岛型地表色 + 心情/真实天气氛围色（仅天空/海/粒子）。
class IslandStyleResolver {
  const IslandStyleResolver();

  MoodIslandConfig resolve({
    required String? moodId,
    RealWeatherSnapshot? weather,
  }) {
    final moodAtmosphere = MoodAtmosphereConfig.resolve(moodId);
    final atmosphere = weather != null
        ? WeatherAtmosphereConfig.blendWithMood(weather, moodAtmosphere)
        : moodAtmosphere;
    return MoodIslandConfig(
      moodId: moodId ?? 'calm',
      styleKey: 'growth_world',
      label: '成长之岛',
      skyTop: atmosphere.skyTop,
      skyBottom: atmosphere.skyBottom,
      sea: IslandVisualConfig.sea,
      sand: IslandVisualConfig.sand,
      accent: IslandVisualConfig.accent,
      grass: IslandVisualConfig.grass,
      flower: IslandVisualConfig.flower,
      waveIntensity: atmosphere.waveIntensity,
      rain: atmosphere.rain,
      wind: atmosphere.windStrength > 0.55,
      islandShape: IslandVisualConfig.fixedShapeKey,
      biome: IslandVisualConfig.fixedBiome,
      ambientParticles: atmosphere.particlePreset,
    );
  }
}
