import 'dart:convert';

import 'package:flutter/services.dart';

enum AppBgmContext {
  island,
  welcome,
  insights,
  more,
}

enum AppSfx {
  tap,
  taskComplete,
  growthGain,
  levelUp,
  momentSaved,
  vipSuccess,
}

class AppAudioAssets {
  const AppAudioAssets._();

  static const bgmIslandDay = 'assets/audio/bgm_island_day_loop.mp3';
  static const bgmIslandNight = 'assets/audio/bgm_island_night_loop.mp3';
  static const bgmInsightsFallback = 'assets/audio/bgm_insights_loop.mp3';
  static const bgmMoreFallback = 'assets/audio/bgm_more_loop.mp3';

  static const sfxTap = 'assets/audio/sfx_tap_soft.wav';
  static const sfxTaskComplete = 'assets/audio/sfx_task_complete.wav';
  static const sfxGrowthGain = 'assets/audio/sfx_growth_gain.wav';
  static const sfxLevelUp = 'assets/audio/sfx_level_up.wav';
  static const sfxMomentSaved = 'assets/audio/sfx_moment_saved.wav';
  static const sfxVipSuccess = 'assets/audio/sfx_vip_success.wav';

  static Future<String> bgmFor(AppBgmContext context, DateTime now) async {
    return switch (context) {
      AppBgmContext.island || AppBgmContext.welcome =>
        _isDaytime(now) ? bgmIslandDay : bgmIslandNight,
      AppBgmContext.insights => await _firstAudioAssetContaining(
          const ['insights', 'instights'],
          fallback: bgmInsightsFallback,
        ),
      AppBgmContext.more => await _firstAudioAssetContaining(
          const ['more'],
          fallback: bgmMoreFallback,
        ),
    };
  }

  static bool usesDaypart(AppBgmContext context) {
    return context == AppBgmContext.island ||
        context == AppBgmContext.welcome;
  }

  static bool _isDaytime(DateTime now) {
    final hour = now.hour;
    return hour >= 6 && hour < 19;
  }

  static Future<String> _firstAudioAssetContaining(
    List<String> tokens, {
    required String fallback,
  }) async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(manifest) as Map<String, dynamic>;
      final matches = decoded.keys
          .where((asset) => asset.startsWith('assets/audio/'))
          .where((asset) {
        final lower = asset.toLowerCase();
        final isAudio = lower.endsWith('.mp3') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.wav') ||
            lower.endsWith('.aac');
        return isAudio && tokens.any(lower.contains);
      }).toList()
        ..sort();
      if (matches.isNotEmpty) return matches.first;
    } catch (_) {}
    return fallback;
  }

  static String sfx(AppSfx effect) {
    return switch (effect) {
      AppSfx.tap => sfxTap,
      AppSfx.taskComplete => sfxTaskComplete,
      AppSfx.growthGain => sfxGrowthGain,
      AppSfx.levelUp => sfxLevelUp,
      AppSfx.momentSaved => sfxMomentSaved,
      AppSfx.vipSuccess => sfxVipSuccess,
    };
  }
}
