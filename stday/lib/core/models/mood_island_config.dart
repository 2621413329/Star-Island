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
    required this.grass,
    required this.flower,
    required this.waveIntensity,
    required this.rain,
    required this.wind,
    required this.islandShape,
    required this.biome,
    required this.ambientParticles,
  });

  final String moodId;
  final String styleKey;
  final String label;
  final Color skyTop;
  final Color skyBottom;
  final Color sea;
  final Color sand;
  final Color accent;
  final Color grass;
  final Color flower;
  final double waveIntensity;
  final bool rain;
  final bool wind;
  final String islandShape;
  final String biome;
  final String ambientParticles;

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
      grass: parse(c['grass'] as String?, const Color(0xFFA8DF9A)),
      flower: parse(c['flower'] as String?, const Color(0xFFF8BBD0)),
      waveIntensity: (c['wave_intensity'] as num?)?.toDouble() ?? 0.4,
      rain: c['rain'] as bool? ?? false,
      wind: c['wind'] as bool? ?? false,
      islandShape: c['island_shape'] as String? ?? 'heart',
      biome: c['biome'] as String? ?? '${moodId}_biome',
      ambientParticles: c['ambient_particles'] as String? ?? 'sparkle',
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
        'style_key': 'dream_coast',
        'config': {
          'label': '活力满满的梦幻海岸',
          'sky_top': '#FFF4DF',
          'sky_bottom': '#BDEFFF',
          'sea': '#21C4D8',
          'sand': '#FFF0D0',
          'accent': '#FFCC4D',
          'grass': '#74D680',
          'flower': '#FF8FB3',
          'wave_intensity': 0.6,
          'rain': false,
          'wind': false,
          'island_shape': 'lagoon',
          'biome': 'dream_coast',
          'ambient_particles': 'golden_sparkle',
        }
      },
      'calm': {
        'style_key': 'serene_lagoon',
        'config': {
          'label': '浅海浮岛',
          'sky_top': '#EAF7FA',
          'sky_bottom': '#D4EFF5',
          'sea': '#B5E6EE',
          'sand': '#FAF6EE',
          'accent': '#8BC49A',
          'grass': '#9BC9A8',
          'flower': '#CDEB8B',
          'wave_intensity': 0.28,
          'rain': false,
          'wind': false,
          'island_shape': 'round',
          'biome': 'serene_lagoon',
          'ambient_particles': 'bloom',
        }
      },
      'thinking': {
        'style_key': 'zen_pool',
        'config': {
          'label': '宁静祥和的冥想岛屿',
          'sky_top': '#EFF8FF',
          'sky_bottom': '#DDECF5',
          'sea': '#7FB8D8',
          'sand': '#EAE7DD',
          'accent': '#42A5F5',
          'grass': '#8FAF88',
          'flower': '#D8C7EE',
          'wave_intensity': 0.25,
          'rain': false,
          'wind': false,
          'island_shape': 'crescent',
          'biome': 'zen_pool',
          'ambient_particles': 'fireflies',
        }
      },
      'sad': {
        'style_key': 'storm_lighthouse',
        'config': {
          'label': '阴云笼罩的孤寂岛屿',
          'sky_top': '#AEB8C2',
          'sky_bottom': '#D5DEE6',
          'sea': '#5F7D8B',
          'sand': '#CFCAC2',
          'accent': '#8EA4B8',
          'grass': '#7D9185',
          'flower': '#B3E5FC',
          'wave_intensity': 0.45,
          'rain': true,
          'wind': false,
          'island_shape': 'round',
          'biome': 'storm_lighthouse',
          'ambient_particles': 'drizzle',
        }
      },
      'angry': {
        'style_key': 'volcanic_ridge',
        'config': {
          'label': '炽热燃烧的火山岛屿',
          'sky_top': '#FFD8C8',
          'sky_bottom': '#FFE6CC',
          'sea': '#445A64',
          'sand': '#5D4037',
          'accent': '#FF6D3A',
          'grass': '#6D4C41',
          'flower': '#FFAB91',
          'wave_intensity': 0.75,
          'rain': false,
          'wind': true,
          'island_shape': 'ridge',
          'biome': 'volcanic_ridge',
          'ambient_particles': 'leaves',
        }
      },
    };
    return MoodIslandRegistry({
      for (final e in data.entries)
        e.key:
            MoodIslandConfig.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }
}
