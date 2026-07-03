import 'package:flutter/material.dart';

import '../../../core/constants/island_weather.dart';
import '../../../core/growth/growth_system.dart';
import '../../../core/growth/level_title_assets.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../core/weather/real_weather_snapshot.dart';
import '../../../core/weather/weather_display.dart';

/// 首页顶部成长等级卡片（原 Island 目录页标签）。
class HomeGrowthLevelCard extends StatelessWidget {
  const HomeGrowthLevelCard({
    super.key,
    required this.summary,
    required this.palette,
    required this.weatherKind,
    required this.weatherLabel,
    this.weather,
  });

  final GrowthSummary summary;
  final MoodPalette palette;
  final IslandWeather weatherKind;
  final String weatherLabel;
  final RealWeatherSnapshot? weather;

  @override
  Widget build(BuildContext context) {
    final nextLabel = summary.nextLevel == null
        ? '已满级 · 岛屿传说'
        : '下一级 Lv.${summary.nextLevel} ${summary.nextLevelTitle ?? ''}'.trim();
    final locationLine = weatherCardLocationLine(
      weather: weather,
      weatherLabel: weatherLabel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EA).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GrowthSystem.levelDisplayLabel(summary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '🔥  ${summary.streakDays} 天',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6D8B74),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          locationLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primary.withValues(alpha: 0.54),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _weatherIcon(weatherKind),
                        size: 14,
                        color: const Color(0xFF75A9D6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            LevelTitleBadgeImage(
              level: summary.level,
              size: 52,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  IconData _weatherIcon(IslandWeather weather) {
    return switch (weather) {
      IslandWeather.sunny => Icons.wb_sunny_rounded,
      IslandWeather.softCloud => Icons.cloud_queue_rounded,
      IslandWeather.overcast => Icons.cloud_rounded,
      IslandWeather.drizzle => Icons.water_drop_rounded,
      IslandWeather.windy => Icons.air_rounded,
    };
  }
}
