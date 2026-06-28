import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/voice/story_voice_recorder.dart';
import '../../../core/theme/mood_theme.dart';

typedef VoiceRecordingResult = ({String path, int durationSec});

/// 微信风格「按住说话」输入面板。
class StoryVoiceInputPanel extends StatefulWidget {
  const StoryVoiceInputPanel({
    super.key,
    required this.palette,
    required this.enabled,
    required this.onRecorded,
    this.onMessage,
  });

  final MoodPalette palette;
  final bool enabled;
  final void Function(VoiceRecordingResult result) onRecorded;
  final void Function(String message)? onMessage;

  @override
  State<StoryVoiceInputPanel> createState() => _StoryVoiceInputPanelState();
}

class _StoryVoiceInputPanelState extends State<StoryVoiceInputPanel>
    with SingleTickerProviderStateMixin {
  final _recorder = StoryVoiceRecorder();
  bool _pressing = false;
  bool _pointerHeld = false;
  bool _cancelIntent = false;
  double _pressStartDy = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.04,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _message(String text) {
    widget.onMessage?.call(text);
  }

  Future<void> _onPressStart(PointerDownEvent event) async {
    if (!widget.enabled || kIsWeb || _pressing) return;
    final maxDurationMessage = context.l10n.voiceMaxDurationReached;
    final startFailedMessage = context.l10n.voiceStartFailed;
    _pointerHeld = true;
    final granted = await _recorder.ensurePermission(onMessage: _message);
    if (!granted || !mounted || !_pointerHeld) return;

    setState(() {
      _pressing = true;
      _cancelIntent = false;
      _pressStartDy = event.position.dy;
    });
    HapticFeedback.mediumImpact();
    _pulseCtrl.repeat(reverse: true);
    try {
      await _recorder.start(
        onMaxDurationReached: () {
          if (_pressing && mounted) {
            _message(maxDurationMessage);
            unawaited(_onPressEnd());
          }
        },
      );
    } catch (e) {
      _message(startFailedMessage(e.toString()));
      await _resetPress();
    }
  }

  Future<void> _onPressMove(PointerMoveEvent event) async {
    if (!_pressing) return;
    final delta = _pressStartDy - event.position.dy;
    final cancel = delta > 72;
    if (cancel != _cancelIntent && mounted) {
      setState(() => _cancelIntent = cancel);
      if (cancel) HapticFeedback.lightImpact();
    }
  }

  Future<void> _onPressEnd() async {
    _pointerHeld = false;
    if (!_pressing) return;
    final cancelledMessage = context.l10n.voiceCancelled;
    final tooShortMessage = context.l10n.voiceTooShort;
    final shouldCancel = _cancelIntent;
    await _resetPress();
    if (shouldCancel) {
      await _recorder.cancel();
      _message(cancelledMessage);
      return;
    }
    final result = await _recorder.stop();
    if (result == null) {
      _message(tooShortMessage);
      return;
    }
    widget.onRecorded(result);
  }

  Future<void> _resetPress() async {
    _pulseCtrl.stop();
    _pulseCtrl.value = 1;
    if (mounted) {
      setState(() {
        _pressing = false;
        _cancelIntent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Listener(
          onPointerDown: _onPressStart,
          onPointerMove: _onPressMove,
          onPointerUp: (_) => _onPressEnd(),
          onPointerCancel: (_) => _onPressEnd(),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _pressing ? _pulseCtrl.value : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.palette.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.palette.accent.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                l10n.voiceHoldToTalk,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.palette.accent.withValues(alpha: 0.92),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        if (_pressing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: _RecordingOverlay(cancelIntent: _cancelIntent),
          ),
      ],
    );
  }
}

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({required this.cancelIntent});

  final bool cancelIntent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: cancelIntent
                ? const Color(0xFF5C4033).withValues(alpha: 0.92)
                : const Color(0xFF3D3229).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cancelIntent ? Icons.close_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                cancelIntent ? l10n.voiceReleaseToCancel : l10n.voiceRecording,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!cancelIntent) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.voiceReleaseToSend,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
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
