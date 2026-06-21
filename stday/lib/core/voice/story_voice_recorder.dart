import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 故事语音录制（m4a / AAC）。
class StoryVoiceRecorder {
  StoryVoiceRecorder();

  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;
  String? _path;

  bool get isRecording => _startedAt != null;

  Future<bool> ensurePermission({
    required void Function(String message) onMessage,
  }) async {
    if (kIsWeb) {
      onMessage('当前平台暂不支持语音录制');
      return false;
    }
    if (!await _recorder.hasPermission()) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        onMessage('需要麦克风权限才能录音');
        return false;
      }
    }
    return true;
  }

  Future<void> start() async {
    if (_startedAt != null) return;
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/story_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: filePath,
    );
    _path = filePath;
    _startedAt = DateTime.now();
  }

  Future<({File file, int durationSec})?> stop() async {
    if (_startedAt == null) return null;
    final path = await _recorder.stop();
    final started = _startedAt!;
    _startedAt = null;
    final resolved = path ?? _path;
    _path = null;
    if (resolved == null || resolved.isEmpty) return null;
    final file = File(resolved);
    if (!await file.exists()) return null;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final duration = elapsed.clamp(1, 120);
    return (file: file, durationSec: duration);
  }

  Future<void> cancel() async {
    if (_startedAt == null) return;
    final path = await _recorder.stop();
    _startedAt = null;
    final resolved = path ?? _path;
    _path = null;
    if (resolved == null) return;
    try {
      final file = File(resolved);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
