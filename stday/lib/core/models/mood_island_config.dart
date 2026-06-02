import 'package:flutter/material.dart';

/// 每种心情独立岛屿配置（与后端 mood_island_styles 表对应）。
class MoodIslandConfig {
  const MoodIslandConfig({
    required this.moodId,
    required this.styleKey,
    required this.label,
    required this.skyTop,
    required this.skyBottom,
    required this.sea,
    required this.sand,
    required this.accent,
    required this.waveIntensity,
    required this.rain,
    required this.wind,
  });

  final String moodId;
  final String styleKey;
  final String label;
  final Color skyTop;
  final Color skyBottom;
  final Color sea;
  final Color sand;
  final Color accent;
  final double waveIntensity;
  final bool rain;
  final bool wind;

  factory MoodIslandConfig.fromJson(String moodId, Map<String, dynamic> json) {
    final c = json['config'] as Map<String, dynamic>? ?? json;
    Color parse(String? h, Color fb) {
      if (h == null || h.length != 7) return fb;
      final v = int.tryParse(h.replaceFirst('#', ''), radix: 16);
      return v == null ? fb : Color(0xFF000000 | v);
    }

    return MoodIslandConfig(
      moodId: moodId,
      styleKey: json['style_key'] as String? ?? '${moodId}_beach',
      label: c['label'] as String? ?? moodId,
      skyTop: parse(c['sky_top'] as String?, const Color(0xFFE3F2FD)),
      skyBottom: parse(c['sky_bottom'] as String?, const Color(0xFFB3E5FC)),
      sea: parse(c['sea'] as String?, const Color(0xFF4FC3F7)),
      sand: parse(c['sand'] as String?, const Color(0xFFFFE0B2)),
      accent: parse(c['accent'] as String?, const Color(0xFFFFCC80)),
      waveIntensity: (c['wave_intensity'] as num?)?.toDouble() ?? 0.4,
      rain: c['rain'] as bool? ?? false,
      wind: c['wind'] as bool? ?? false,
    );
  }
}

class MoodIslandRegistry {
  MoodIslandRegistry(this._byMood);

  final Map<String, MoodIslandConfig> _byMood;

  MoodIslandConfig resolve(String? moodId) {
    if (moodId != null && _byMood.containsKey(moodId)) return _byMood[moodId]!;
    return _byMood['calm'] ?? _byMood.values.first;
  }

  List<MoodIslandConfig> get all => _byMood.values.toList();

  static MoodIslandRegistry defaults() {
    final data = {
      'happy': {
        'style_key': 'sunny_beach',
        'config': {
          'label': '晴朗沙滩岛',
          'sky_top': '#FFF8ED',
          'sky_bottom': '#FFEFD4',
          'sea': '#4FC3F7',
          'sand': '#FFE0B2',
          'accent': '#FFD54F',
          'wave_intensity': 0.6,
          'rain': false,
          'wind': false,
        }
      },
      'calm': {
        'style_key': 'soft_beach',
        'config': {
          'label': '温柔海湾岛',
          'sky_top': '#F2FAF7',
          'sky_bottom': '#E3F4EE',
          'sea': '#81D4FA',
          'sand': '#FFF3E0',
          'accent': '#A8DFCF',
          'wave_intensity': 0.35,
          'rain': false,
          'wind': false,
        }
      },
      'thinking': {
        'style_key': 'misty_beach',
        'config': {
          'label': '静静海湾岛',
          'sky_top': '#ECEFF1',
          'sky_bottom': '#CFD8DC',
          'sea': '#90A4AE',
          'sand': '#ECEFF1',
          'accent': '#B0BEC5',
          'wave_intensity': 0.25,
          'rain': false,
          'wind': false,
        }
      },
      'sad': {
        'style_key': 'drizzle_beach',
        'config': {
          'label': '细雨沙滩岛',
          'sky_top': '#90A4AE',
          'sky_bottom': '#CFD8DC',
          'sea': '#607D8B',
          'sand': '#D7CCC8',
          'accent': '#90A4AE',
          'wave_intensity': 0.45,
          'rain': true,
          'wind': false,
        }
      },
      'angry': {
        'style_key': 'windy_beach',
        'config': {
          'label': '微风海岸岛',
          'sky_top': '#FFCCBC',
          'sky_bottom': '#FFE0B2',
          'sea': '#4DD0E1',
          'sand': '#FFCCBC',
          'accent': '#FF8A65',
          'wave_intensity': 0.75,
          'rain': false,
          'wind': true,
        }
      },
    };
    return MoodIslandRegistry({
      for (final e in data.entries) e.key: MoodIslandConfig.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }
}
