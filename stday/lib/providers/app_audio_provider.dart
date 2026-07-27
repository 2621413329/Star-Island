import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/app_audio_controller.dart';
import '../core/audio/app_audio_settings.dart';

final appAudioControllerProvider = Provider<AppAudioController>((ref) {
  final controller = AppAudioController();
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final appAudioSettingsProvider =
    AsyncNotifierProvider<AppAudioSettingsNotifier, AppAudioSettings>(
  AppAudioSettingsNotifier.new,
);

class AppAudioSettingsNotifier extends AsyncNotifier<AppAudioSettings> {
  @override
  Future<AppAudioSettings> build() async {
    final settings = await _loadSettings();
    unawaited(_syncController(settings));
    return settings;
  }

  Future<AppAudioSettings> _loadSettings() async {
    try {
      return await AppAudioSettings.load();
    } catch (e, st) {
      debugPrint('Audio settings load failed, using defaults: $e\n$st');
      return const AppAudioSettings();
    }
  }

  Future<void> setBgmEnabled(bool enabled) async {
    await _update((settings) => settings.copyWith(bgmEnabled: enabled));
  }

  Future<void> setSfxEnabled(bool enabled) async {
    await _update((settings) => settings.copyWith(sfxEnabled: enabled));
  }

  Future<void> setBgmVolume(double volume) async {
    await _update((settings) => settings.copyWith(bgmVolume: volume));
  }

  Future<void> setSfxVolume(double volume) async {
    await _update((settings) => settings.copyWith(sfxVolume: volume));
  }

  Future<void> _update(
      AppAudioSettings Function(AppAudioSettings) apply) async {
    final current = state.valueOrNull ?? await AppAudioSettings.load();
    final next = apply(current);
    state = AsyncData(next);
    await next.save();
    unawaited(_syncController(next));
  }

  Future<void> _syncController(AppAudioSettings settings) async {
    try {
      await ref.read(appAudioControllerProvider).updateSettings(settings);
    } catch (e, st) {
      debugPrint('Audio controller settings sync skipped: $e\n$st');
    }
  }
}
