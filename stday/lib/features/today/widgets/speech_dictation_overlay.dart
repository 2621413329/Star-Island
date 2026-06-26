import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';

/// 文字记录时长按麦克风的录音/转写浮层（与语音记录弹窗风格一致）。
class SpeechDictationOverlay extends StatelessWidget {
  const SpeechDictationOverlay({super.key, this.transcribing = false});

  final bool transcribing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF3D3229).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                transcribing ? Icons.text_fields_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                transcribing ? '正在转为文字' : l10n.voiceRecording,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transcribing ? '请稍候' : '松开结束 · 转为文字',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
