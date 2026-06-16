import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../design_system/companion_speech_bubble.dart';

/// 岛屿小人对话气泡（点击岛上小人后展示）。
class IslandCompanionSpeechOverlay extends StatelessWidget {
  const IslandCompanionSpeechOverlay({
    super.key,
    required this.palette,
    required this.text,
    this.showWriteStoryAction = false,
    this.onWriteStory,
  });

  final MoodPalette palette;
  final String text;
  final bool showWriteStoryAction;
  final VoidCallback? onWriteStory;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 128,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompanionSpeechBubble(
            text: text,
            palette: palette,
            maxWidth: 320,
            tailTipInsetFromRight: MediaQuery.sizeOf(context).width / 2,
          ),
          if (showWriteStoryAction && onWriteStory != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onWriteStory,
              style: TextButton.styleFrom(
                backgroundColor: palette.card.withValues(alpha: 0.92),
                foregroundColor: palette.accent,
              ),
              child: const Text('去写今天的故事'),
            ),
          ],
        ],
      ),
    );
  }
}
