import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 故事语音录制前的麦克风权限（iOS / Android）。
class MicrophonePermission {
  static Future<bool> ensure({
    required void Function(String message) onMessage,
  }) async {
    if (kIsWeb) {
      onMessage('当前平台暂不支持语音录制');
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _requestPermission(
        Permission.microphone,
        deniedMessage: '需要麦克风权限才能录音',
        blockedMessage: '请在系统设置中开启麦克风权限后再试',
        onMessage: onMessage,
      );
      if (!granted) return false;
      final recorder = AudioRecorder();
      try {
        return await recorder.hasPermission();
      } finally {
        await recorder.dispose();
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _requestPermission(
        Permission.microphone,
        deniedMessage: '需要麦克风权限才能录音',
        blockedMessage: '请在系统设置中开启麦克风权限后再试',
        onMessage: onMessage,
      );
      if (!granted) return false;
    }

    final recorder = AudioRecorder();
    try {
      final granted = await recorder.hasPermission();
      if (!granted) {
        onMessage('需要麦克风权限才能录音');
        return false;
      }
      return true;
    } finally {
      await recorder.dispose();
    }
  }

  static Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
    required String blockedMessage,
    required void Function(String message) onMessage,
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
}
