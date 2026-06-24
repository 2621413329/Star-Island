import 'dart:ui';

import 'package:flutter/material.dart' show Color;

/// 岛屿场景时段：早 / 中 / 晚。
enum DayPhase {
  morning,
  noon,
  evening;

  String get label => switch (this) {
        DayPhase.morning => '早晨',
        DayPhase.noon => '正午',
        DayPhase.evening => '傍晚',
      };
}

/// 根据当前时间解析时段。
DayPhase resolveDayPhase([DateTime? time]) {
  final hour = (time ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 11) return DayPhase.morning;
  if (hour >= 11 && hour < 17) return DayPhase.noon;
  return DayPhase.evening;
}

/// 时段光照参数：太阳位置、天空色温、地面投影方向。
class DayPhaseLightingPreset {
  const DayPhaseLightingPreset({
    required this.skyTop,
    required this.skyBottom,
    required this.sunIntensity,
    required this.sunX,
    required this.sunY,
    required this.shadowDx,
    required this.shadowDy,
    required this.shadowStretch,
    required this.shadowAlpha,
    required this.lightWarmth,
    required this.ambientShadeStrength,
  });

  final Color skyTop;
  final Color skyBottom;
  final double sunIntensity;
  final double sunX;
  final double sunY;
  final double shadowDx;
  final double shadowDy;
  final double shadowStretch;
  final double shadowAlpha;
  final double lightWarmth;
  final double ambientShadeStrength;

  /// 光源方向（归一化，指向太阳）。
  Offset get lightDirection {
    final len = (Offset(sunX - 0.5, sunY - 0.5)).distance;
    if (len < 0.001) return const Offset(0, -1);
    return Offset((sunX - 0.5) / len, (sunY - 0.5) / len);
  }

  static DayPhaseLightingPreset forPhase(DayPhase phase) => switch (phase) {
        DayPhase.morning => const DayPhaseLightingPreset(
            skyTop: Color(0xFFFFE8C8),
            skyBottom: Color(0xFFFFF0D6),
            sunIntensity: 0.82,
            sunX: 0.16,
            sunY: 0.22,
            shadowDx: 0.22,
            shadowDy: 0.06,
            shadowStretch: 1.45,
            shadowAlpha: 0.20,
            lightWarmth: 0.78,
            ambientShadeStrength: 0.14,
          ),
        DayPhase.noon => const DayPhaseLightingPreset(
            skyTop: Color(0xFFE8F6FA),
            skyBottom: Color(0xFFD4EFF5),
            sunIntensity: 1.05,
            sunX: 0.50,
            sunY: 0.14,
            shadowDx: 0.02,
            shadowDy: 0.10,
            shadowStretch: 0.92,
            shadowAlpha: 0.16,
            lightWarmth: 0.35,
            ambientShadeStrength: 0.18,
          ),
        DayPhase.evening => const DayPhaseLightingPreset(
            skyTop: Color(0xFFFFD4A8),
            skyBottom: Color(0xFFFFE8CC),
            sunIntensity: 0.68,
            sunX: 0.84,
            sunY: 0.26,
            shadowDx: -0.24,
            shadowDy: 0.07,
            shadowStretch: 1.50,
            shadowAlpha: 0.22,
            lightWarmth: 0.88,
            ambientShadeStrength: 0.16,
          ),
      };

  /// 将时段天空色与情绪氛围色混合，保留情绪差异。
  DayPhaseLightingPreset blendWithAtmosphere({
    required Color moodSkyTop,
    required Color moodSkyBottom,
    required double moodSunIntensity,
  }) {
    const blend = 0.42;
    return DayPhaseLightingPreset(
      skyTop: Color.lerp(skyTop, moodSkyTop, blend)!,
      skyBottom: Color.lerp(skyBottom, moodSkyBottom, blend)!,
      sunIntensity: (sunIntensity * 0.65 + moodSunIntensity * 0.35).clamp(0.2, 1.2),
      sunX: sunX,
      sunY: sunY,
      shadowDx: shadowDx,
      shadowDy: shadowDy,
      shadowStretch: shadowStretch,
      shadowAlpha: shadowAlpha,
      lightWarmth: lightWarmth,
      ambientShadeStrength: ambientShadeStrength,
    );
  }
}
