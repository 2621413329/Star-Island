import 'package:shared_preferences/shared_preferences.dart';

class AppAudioSettings {
  const AppAudioSettings({
    this.bgmEnabled = true,
    this.sfxEnabled = true,
    this.bgmVolume = 0.42,
    this.sfxVolume = 0.72,
  });

  static const _bgmEnabledKey = 'app_audio_bgm_enabled';
  static const _sfxEnabledKey = 'app_audio_sfx_enabled';
  static const _bgmVolumeKey = 'app_audio_bgm_volume';
  static const _sfxVolumeKey = 'app_audio_sfx_volume';

  final bool bgmEnabled;
  final bool sfxEnabled;
  final double bgmVolume;
  final double sfxVolume;

  static double _clampVolume(double value) => value.clamp(0, 1).toDouble();

  AppAudioSettings copyWith({
    bool? bgmEnabled,
    bool? sfxEnabled,
    double? bgmVolume,
    double? sfxVolume,
  }) {
    return AppAudioSettings(
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      bgmVolume: _clampVolume(bgmVolume ?? this.bgmVolume),
      sfxVolume: _clampVolume(sfxVolume ?? this.sfxVolume),
    );
  }

  static Future<AppAudioSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppAudioSettings(
      bgmEnabled: prefs.getBool(_bgmEnabledKey) ?? true,
      sfxEnabled: prefs.getBool(_sfxEnabledKey) ?? true,
      bgmVolume: _clampVolume(prefs.getDouble(_bgmVolumeKey) ?? 0.42),
      sfxVolume: _clampVolume(prefs.getDouble(_sfxVolumeKey) ?? 0.72),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_bgmEnabledKey, bgmEnabled),
      prefs.setBool(_sfxEnabledKey, sfxEnabled),
      prefs.setDouble(_bgmVolumeKey, bgmVolume),
      prefs.setDouble(_sfxVolumeKey, sfxVolume),
    ]);
  }
}
