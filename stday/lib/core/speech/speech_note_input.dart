import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_input_bridge.dart';

/// 日常备注语音输入（Android / 鸿蒙 / iOS）。
class SpeechNoteInput {
  SpeechNoteInput({
    required this.onText,
    required this.onListening,
    required this.onMessage,
    this.prompt = '请说出你的日常',
  });

  final void Function(String text, {required bool isFinal}) onText;
  final void Function(bool listening) onListening;
  final void Function(String message) onMessage;
  final String prompt;

  SpeechToText? _engine;
  bool _ready = false;
  bool _starting = false;
  bool _listening = false;
  String _sessionText = '';
  Completer<void>? _finalResultCompleter;

  bool get isListening => _listening;

  String get sessionText => _sessionText;

  static bool get isSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  SpeechToText get _speechEngine => _engine ??= SpeechToText();

  Future<void> toggle() async {
    if (_listening) {
      await stop();
    } else {
      await start();
    }
  }

  Future<bool> start({bool forceStreaming = false}) async {
    if (!isSupported) {
      if (kDebugMode) {
        debugPrint('SpeechNoteInput.start: platform not supported');
      }
      onMessage('当前平台暂不支持语音转文字，请使用键盘输入');
      return false;
    }
    if (_starting || _listening) {
      if (kDebugMode) {
        debugPrint(
          'SpeechNoteInput.start: busy starting=$_starting listening=$_listening',
        );
      }
      return false;
    }

    _starting = true;
    _sessionText = '';
    _finalResultCompleter = Completer<void>();
    try {
      if (!await _ensurePermissions()) {
        if (kDebugMode) {
          debugPrint('SpeechNoteInput.start: permissions denied');
        }
        return false;
      }
      await _waitForNextFrame();

      if (!forceStreaming &&
          _isAndroid &&
          await SpeechInputBridge.shouldPreferIntentRecognition()) {
        final usedIntent = await _startAndroidIntent();
        if (!usedIntent) {
          final streamed = await _startStreaming();
          if (!streamed) {
            onMessage('语音转文字不可用，请确认系统语音助手已启用，或改用键盘输入');
          }
          return streamed;
        }
        return true;
      }

      final streamed = await _startStreaming();
      if (!streamed && _isAndroid) {
        if (await SpeechInputBridge.canStartIntentRecognition()) {
          return await _startAndroidIntent();
        }
        onMessage('语音转文字不可用，请检查麦克风权限或安装系统语音识别服务');
        return false;
      }
      return streamed;
    } finally {
      _starting = false;
    }
  }

  Future<String> finishSession() async {
    final wasListening = _listening || _starting;
    _starting = false;
    if (_engine != null && _speechEngine.isListening) {
      try {
        await _speechEngine.stop();
      } catch (_) {}
    }
    _setListening(false);
    if (wasListening) {
      final completer = _finalResultCompleter;
      if (completer != null && !completer.isCompleted) {
        await Future.any([
          completer.future,
          Future<void>.delayed(const Duration(milliseconds: 650)),
        ]);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
    return _sessionText.trim();
  }

  Future<void> stop() async {
    await finishSession();
  }

  void dispose() {
    if (_listening) {
      unawaited(stop());
    }
  }

  Future<bool> _startStreaming() async {
    _ready = _ready ||
        await _speechEngine.initialize(
          onStatus: _handleSpeechStatus,
          onError: (error) {
            if (kDebugMode) {
              debugPrint('Speech error: ${error.errorMsg}');
            }
            _setListening(false);
            if (error.permanent) {
              onMessage('语音识别出错：${error.errorMsg}');
            }
          },
          debugLogging: kDebugMode,
          options: _initOptions(),
        );

    if (!_ready || !_speechEngine.isAvailable) {
      if (kDebugMode) {
        debugPrint('Speech initialize failed: ready=$_ready');
      }
      return false;
    }

    if (!await _speechEngine.hasPermission) {
      onMessage('需要麦克风权限才能使用语音转文字');
      return false;
    }

    if (_speechEngine.isListening) {
      try {
        await _speechEngine.stop();
      } catch (_) {}
    }

    try {
      await _speechEngine.listen(
        onResult: _handleSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: await _resolveSpeechLocale(),
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      // listen() 返回时 isListening 可能尚未更新，以状态回调为准；此处先乐观开启。
      _setListening(true);
      return true;
    } on ListenFailedException catch (e) {
      _setListening(false);
      if (kDebugMode) {
        debugPrint('Listen failed: ${e.message}');
      }
      return false;
    } on SpeechToTextNotInitializedException {
      _setListening(false);
      return false;
    } catch (e) {
      _setListening(false);
      if (kDebugMode) {
        debugPrint('Speech streaming failed: $e');
      }
      return false;
    }
  }

  /// 返回是否成功弹出系统语音识别。
  Future<bool> _startAndroidIntent() async {
    if (!await SpeechInputBridge.canStartIntentRecognition()) {
      return false;
    }
    try {
      final spoken = await SpeechInputBridge.startIntentRecognition(
        prompt: prompt,
      );
      if (spoken == null) {
        return true;
      }
      if (spoken.trim().isEmpty) {
        onMessage('未识别到语音，请重试或改用键盘输入');
        return true;
      }
      onText(spoken.trim(), isFinal: true);
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'UNAVAILABLE') {
        return false;
      }
      onMessage('语音转文字失败，请改用键盘输入');
      if (kDebugMode) {
        debugPrint('Intent speech failed: $e');
      }
      return false;
    } catch (e) {
      onMessage('语音转文字失败，请改用键盘输入');
      if (kDebugMode) {
        debugPrint('Intent speech failed: $e');
      }
      return false;
    }
  }

  List<SpeechConfigOption> _initOptions() {
    if (_isAndroid) {
      return [
        SpeechToText.androidNoBluetooth,
        SpeechToText.androidAlwaysUseStop,
      ];
    }
    if (_isIos) {
      return [SpeechToText.iosNoBluetooth];
    }
    return [];
  }

  Future<String?> _resolveSpeechLocale() async {
    try {
      final locales = await _speechEngine.locales();
      if (locales.isEmpty) return null;
      const preferred = ['zh-CN', 'zh_CN', 'zh-TW', 'zh_TW', 'en-US', 'en_US'];
      for (final id in preferred) {
        for (final locale in locales) {
          final normalized = locale.localeId.replaceAll('_', '-');
          if (normalized == id.replaceAll('_', '-')) {
            return locale.localeId;
          }
        }
      }
      return locales.first.localeId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensurePermissions() async {
    if (_isIos) {
      final micGranted = await _requestPermission(
        Permission.microphone,
        deniedMessage: '需要麦克风权限才能使用语音输入',
        blockedMessage: '请在系统设置中开启麦克风权限后再试',
      );
      if (!micGranted) return false;

      return _requestPermission(
        Permission.speech,
        deniedMessage: '需要语音识别权限才能使用语音输入',
        blockedMessage: '请在系统设置中开启语音识别权限后再试',
      );
    }

    if (_isAndroid) {
      // 国产 ROM 上 permission_handler 状态可能不准，申请失败也不阻断，交给插件再试。
      await _tryRequestPermission(Permission.microphone);
    }
    return true;
  }

  Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
    required String blockedMessage,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      onMessage(blockedMessage);
      return false;
    }
    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    onMessage(deniedMessage);
    return false;
  }

  Future<void> _tryRequestPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return;
    if (!status.isPermanentlyDenied) {
      await permission.request();
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    try {
      final spoken = result.recognizedWords.trim();
      if (spoken.isEmpty) return;
      _sessionText = spoken;
      onText(spoken, isFinal: result.finalResult);
      if (result.finalResult) {
        _completeFinalResult();
        _setListening(false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Speech result handling failed: $e');
      }
      _setListening(false);
    }
  }

  void _completeFinalResult() {
    final completer = _finalResultCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _handleSpeechStatus(String status) {
    if (status == 'listening') {
      _setListening(true);
    } else if (status == 'done' || status == 'notListening') {
      _completeFinalResult();
      _setListening(false);
    }
  }

  void _setListening(bool value) {
    if (_listening == value) return;
    if (kDebugMode) {
      debugPrint('SpeechNoteInput._setListening($value)');
    }
    _listening = value;
    onListening(value);
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
