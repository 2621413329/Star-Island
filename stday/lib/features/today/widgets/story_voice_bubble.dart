import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/voice/voice_url.dart';

/// 微信风格语音播放气泡（支持远程 URL 或本地录音文件）。
class StoryVoiceBubble extends StatefulWidget {
  const StoryVoiceBubble({
    super.key,
    required this.durationSec,
    this.voiceUrl,
    this.localFilePath,
    this.compact = false,
    this.accentColor = const Color(0xFF6B8F71),
  });

  final String? voiceUrl;
  final String? localFilePath;
  final int durationSec;
  final bool compact;
  final Color accentColor;

  @override
  State<StoryVoiceBubble> createState() => _StoryVoiceBubbleState();
}

class _StoryVoiceBubbleState extends State<StoryVoiceBubble> {
  static AudioPlayer? _activePlayer;

  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  Duration _position = Duration.zero;
  bool _ready = false;
  String? _loadError;
  String? _loadedSourceKey;

  String get _sourceKey => widget.localFilePath ?? widget.voiceUrl ?? '';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  @override
  void didUpdateWidget(StoryVoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localFilePath != widget.localFilePath ||
        oldWidget.voiceUrl != widget.voiceUrl) {
      unawaited(_initPlayer(force: true));
    }
  }

  Future<void> _initPlayer({bool force = false}) async {
    if (!force && _loadedSourceKey == _sourceKey && _ready) return;
    if (_sourceKey.isEmpty) return;
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.speech());
      }
      await _player.stop();
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        await _player.setFilePath(widget.localFilePath!);
      } else {
        await _player.setUrl(momentVoiceFullUrl(widget.voiceUrl));
      }
      _loadedSourceKey = _sourceKey;
      if (!mounted) return;
      setState(() {
        _ready = true;
        _loadError = null;
        _position = Duration.zero;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _ready = false;
          _loadError = '语音加载失败';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    if (_activePlayer == _player) _activePlayer = null;
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _positionSub ??= _player.positionStream.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _stateSub ??= _player.playerStateStream.listen((state) {
      if (mounted) setState(() {});
      if (state.processingState == ProcessingState.completed) {
        unawaited(_player.pause());
        unawaited(_player.seek(Duration.zero));
        if (_activePlayer == _player) _activePlayer = null;
      }
    });
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_player.playing) {
      await _player.pause();
      if (_activePlayer == _player) _activePlayer = null;
      return;
    }
    if (_activePlayer != null && _activePlayer != _player) {
      await _activePlayer!.pause();
      await _activePlayer!.seek(Duration.zero);
    }
    _activePlayer = _player;
    await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Text(
        _loadError!,
        style: TextStyle(
          fontSize: 12,
          color: widget.accentColor.withValues(alpha: 0.7),
        ),
      );
    }

    final total = Duration(seconds: widget.durationSec.clamp(1, 9999));
    final playing = _player.playing;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final label = playing
        ? formatVoiceDuration(_position.inSeconds)
        : formatVoiceDuration(widget.durationSec);

    return Material(
      color: widget.accentColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _ready ? _toggle : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 14,
            vertical: widget.compact ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: widget.compact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      '语音',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.accentColor.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
              if (playing && !widget.compact) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor:
                        widget.accentColor.withValues(alpha: 0.18),
                    color: widget.accentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
