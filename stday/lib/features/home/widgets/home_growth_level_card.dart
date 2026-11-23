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
        color: palette.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LevelTitleBadgeImage(
              level: summary.level,
              size: 44,
              borderRadius: 12,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GrowthSystem.levelDisplayLabel(summary),
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextLabel,
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (locationLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _weatherIcon(weatherKind),
                          size: 14,
                          color: palette.accent.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationLine,
                            style: TextStyle(
                              color: palette.primary.withValues(alpha: 0.62),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
