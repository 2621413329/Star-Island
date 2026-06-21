import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../permissions/microphone_permission.dart';
import 'voice_file_io_export.dart';

/// 故事语音录制（m4a / AAC）。
class StoryVoiceRecorder {
  StoryVoiceRecorder();

  static const minDurationSec = 1;
  static const maxDurationSec = 120;

  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;
  String? _path;
  Timer? _maxDurationTimer;
  VoidCallback? _onMaxDurationReached;

  bool get isRecording => _startedAt != null;

  Future<bool> ensurePermission({
    required void Function(String message) onMessage,
  }) {
    return MicrophonePermission.ensure(onMessage: onMessage);
  }

  Future<void> start({VoidCallback? onMaxDurationReached}) async {
    if (_startedAt != null) return;
    _onMaxDurationReached = onMaxDurationReached;
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
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(
      const Duration(seconds: maxDurationSec),
      () => _onMaxDurationReached?.call(),
    );
  }

  Future<({String path, int durationSec})?> stop() async {
    if (_startedAt == null) return null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _onMaxDurationReached = null;
    final path = await _recorder.stop();
    final started = _startedAt!;
    _startedAt = null;
    final resolved = path ?? _path;
    _path = null;
    if (resolved == null || resolved.isEmpty) return null;
    if (!await voiceFileExists(resolved)) return null;
    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    if (elapsedMs < minDurationSec * 1000) {
      await deleteVoiceFile(resolved);
      return null;
    }
    final duration = (elapsedMs / 1000).ceil().clamp(minDurationSec, maxDurationSec);
    return (path: resolved, durationSec: duration);
  }

  Future<void> cancel() async {
    if (_startedAt == null) return;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _onMaxDurationReached = null;
    final path = await _recorder.stop();
    _startedAt = null;
    final resolved = path ?? _path;
    _path = null;
    if (resolved == null) return;
    await deleteVoiceFile(resolved);
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
