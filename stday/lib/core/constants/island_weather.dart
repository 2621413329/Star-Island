import 'package:flutter/material.dart';

import 'catalog.dart';

enum IslandWeather { sunny, softCloud, overcast, drizzle, windy }

IslandWeather weatherForMood(String? moodId) {
  switch (moodId) {
    case 'happy':
      return IslandWeather.sunny;
    case 'calm':
      return IslandWeather.softCloud;
    case 'thinking':
      return IslandWeather.overcast;
    case 'sad':
      return IslandWeather.drizzle;
    case 'angry':
      return IslandWeather.windy;
    default:
      return IslandWeather.softCloud;
  }
}

class IslandSkyStyle {
  const IslandSkyStyle({
    required this.top,
    required this.bottom,
    required this.sun,
    required this.cloudOpacity,
    required this.rain,
    required this.wind,
  });

  final Color top;
  final Color bottom;
  final Color? sun;
  final double cloudOpacity;
  final bool rain;
  final bool wind;
}

IslandSkyStyle skyStyleForMood(String? moodId) {
  final c = moodId != null ? moodColor(moodId) : const Color(0xFF87CEEB);
  switch (weatherForMood(moodId)) {
    case IslandWeather.sunny:
      return IslandSkyStyle(
        top: Color.lerp(c, Colors.white, 0.55)!,
        bottom: Color.lerp(c, const Color(0xFFFFF8E7), 0.4)!,
        sun: const Color(0xFFFFE082),
        cloudOpacity: 0.15,
        rain: false,
        wind: false,
      );
    case IslandWeather.softCloud:
      return IslandSkyStyle(
        top: Color.lerp(c, Colors.white, 0.65)!,
        bottom: Color.lerp(c, Colors.white, 0.45)!,
        sun: Color.lerp(c, Colors.white, 0.3),
        cloudOpacity: 0.45,
        rain: false,
        wind: false,
      );
    case IslandWeather.overcast:
      return const IslandSkyStyle(
        top: Color(0xFFB0BEC5),
        bottom: Color(0xFFECEFF1),
        sun: null,
        cloudOpacity: 0.7,
        rain: false,
        wind: false,
      );
    case IslandWeather.drizzle:
      return const IslandSkyStyle(
        top: Color(0xFF90A4AE),
        bottom: Color(0xFFCFD8DC),
        sun: null,
        cloudOpacity: 0.85,
        rain: true,
        wind: false,
      );
    case IslandWeather.windy:
      return IslandSkyStyle(
        top: Color.lerp(c, const Color(0xFFFFCDD2), 0.5)!,
        bottom: Color.lerp(c, Colors.white, 0.5)!,
        sun: null,
        cloudOpacity: 0.55,
        rain: false,
        wind: true,
      );
  }
}
