import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_assets.dart';
import 'app_audio_settings.dart';

class AppAudioController {
  AppAudioController();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  AppAudioSettings _settings = const AppAudioSettings();
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  StreamSubscription<AVAudioSessionSilenceSecondaryAudioHintType>?
      _secondaryAudioHintSub;
  Timer? _daypartRefreshTimer;
  AppBgmContext? _activeBgmContext;
  String? _activeBgmKey;
  bool _sessionConfigured = false;
  String? _loadedBgmAsset;
  int _bgmOpGeneration = 0;

  Future<void> updateSettings(AppAudioSettings settings) async {
    _settings = settings;
    await _bgmPlayer.setVolume(settings.bgmVolume);
    await _sfxPlayer.setVolume(settings.sfxVolume);
    await _syncBgm();
  }

  Future<void> setBgmContext(
    AppBgmContext? context, {
    required String key,
  }) async {
    final generation = ++_bgmOpGeneration;
    if (_activeBgmContext == context && _activeBgmKey == key) {
      await _syncBgm(expectedGeneration: generation);
      return;
    }
    _activeBgmContext = context;
    _activeBgmKey = key;
    _loadedBgmAsset = null;
    await _syncBgm(expectedGeneration: generation);
  }

  Future<void> handleLifecycle(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _loadedBgmAsset = null;
      await _syncBgm();
    } else {
      await _pauseBgm();
    }
  }

  Future<void> playSfx(AppSfx effect) async {
    if (!_settings.sfxEnabled || _settings.sfxVolume <= 0) return;
    try {
      await _ensureSession();
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_settings.sfxVolume);
      await _sfxPlayer.setAsset(AppAudioAssets.sfx(effect));
      await _sfxPlayer.play();
    } catch (e, st) {
      debugPrint('SFX skipped (${effect.name}): $e\n$st');
    }
  }

  bool _isStaleBgmOp(int? expectedGeneration) {
    return expectedGeneration != null &&
        expectedGeneration != _bgmOpGeneration;
  }

  Future<void> _syncBgm({int? expectedGeneration}) async {
    if (_isStaleBgmOp(expectedGeneration)) return;

    final context = _activeBgmContext;
    if (context == null || !_settings.bgmEnabled || _settings.bgmVolume <= 0) {
      if (_isStaleBgmOp(expectedGeneration)) return;
      await _pauseBgm(deactivateSession: true);
      return;
    }

    try {
      await _ensureSession();
      if (_isStaleBgmOp(expectedGeneration)) return;
      if (await _shouldSkipBgmForOtherAudio()) {
        if (_isStaleBgmOp(expectedGeneration)) return;
        await _pauseBgm();
        return;
      }
      final session = await AudioSession.instance;
      final activated = await session.setActive(true);
      if (!activated) {
        if (_isStaleBgmOp(expectedGeneration)) return;
        await _pauseBgm();
        return;
      }

      final asset = await AppAudioAssets.bgmFor(context, DateTime.now());
      if (_isStaleBgmOp(expectedGeneration)) return;
      if (_loadedBgmAsset != asset ||
          _bgmPlayer.processingState == ProcessingState.idle) {
        await _bgmPlayer.stop();
        await _bgmPlayer.setAsset(asset);
        await _bgmPlayer.setLoopMode(LoopMode.one);
        await _bgmPlayer.seek(Duration.zero);
        _loadedBgmAsset = asset;
      }
      await _bgmPlayer.setVolume(_settings.bgmVolume);
      if (AppAudioAssets.usesDaypart(context)) {
        _scheduleDaypartRefresh();
      } else {
        _daypartRefreshTimer?.cancel();
      }
      if (_isStaleBgmOp(expectedGeneration)) return;
      if (!_bgmPlayer.playing) {
        await _bgmPlayer.play();
      }
    } catch (e, st) {
      if (_isStaleBgmOp(expectedGeneration)) return;
      _loadedBgmAsset = null;
      await _pauseBgm();
      debugPrint('BGM skipped: $e\n$st');
    }
  }

  Future<void> _pauseBgm({bool deactivateSession = false}) async {
    try {
      _daypartRefreshTimer?.cancel();
      await _bgmPlayer.pause();
      if (deactivateSession) {
        final session = await AudioSession.instance;
        await session.setActive(false);
      }
    } catch (_) {}
  }

  Future<void> _ensureSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    _interruptionSub = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        unawaited(_pauseBgm());
      } else {
        unawaited(_syncBgm());
      }
    });
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) {
      unawaited(_pauseBgm());
    });
    if (!kIsWeb && Platform.isIOS) {
      _secondaryAudioHintSub =
          AVAudioSession().silenceSecondaryAudioHintStream.listen((hint) {
        if (hint == AVAudioSessionSilenceSecondaryAudioHintType.begin) {
          unawaited(_pauseBgm());
        } else {
          unawaited(_syncBgm());
        }
      });
    }
    _sessionConfigured = true;
  }

  Future<bool> _shouldSkipBgmForOtherAudio() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      final session = AVAudioSession();
      return await session.isOtherAudioPlaying ||
          await session.secondaryAudioShouldBeSilencedHint;
    } catch (_) {
      return false;
    }
  }

  void _scheduleDaypartRefresh() {
    _daypartRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextBoundary = now.hour < 6
        ? DateTime(now.year, now.month, now.day, 6)
        : now.hour < 19
            ? DateTime(now.year, now.month, now.day, 19)
            : DateTime(now.year, now.month, now.day + 1, 6);
    _daypartRefreshTimer = Timer(nextBoundary.difference(now), () {
      _loadedBgmAsset = null;
      unawaited(_syncBgm());
    });
  }

  Future<void> dispose() async {
    _daypartRefreshTimer?.cancel();
    await _interruptionSub?.cancel();
    await _becomingNoisySub?.cancel();
    await _secondaryAudioHintSub?.cancel();
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
