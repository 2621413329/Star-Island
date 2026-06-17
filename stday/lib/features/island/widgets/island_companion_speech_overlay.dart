import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../design_system/companion_speech_bubble.dart';
import '../../../world/behaviors/protagonist_behavior.dart';

/// 岛屿小人对话气泡（点击岛上小人后展示，紧贴小人头顶、无三角）。
class IslandCompanionSpeechOverlay extends StatelessWidget {
  const IslandCompanionSpeechOverlay({
    super.key,
    required this.palette,
    required this.text,
    required this.viewportSize,
    this.showWriteStoryAction = false,
    this.onWriteStory,
  });

  final MoodPalette palette;
  final String text;
  final Size viewportSize;
  final bool showWriteStoryAction;
  final VoidCallback? onWriteStory;

  static const _headGap = 4.0;
  static const _horizontalPadding = 16.0;

  /// 与 [CharacterLayer] cozy 模式一致的角色尺寸估算。
  static double _companionCharSize(double viewportWidth) {
    return (viewportWidth * 0.148).clamp(34.0, 112.0);
  }

  /// 小人头顶 Y（相对视口顶部），与角色层绘制逻辑对齐。
  static double _companionHeadTop(Size size) {
    const base = ProtagonistBehavior.defaultBase;
    final charSize = _companionCharSize(size.width);
    final charHeight = charSize * 1.15;
    final groundY = base.dy * size.height;
    return groundY - charHeight * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final w = viewportSize.width;
    final h = viewportSize.height;
    final headTop = _companionHeadTop(viewportSize);
    final bubbleBottom = h - headTop + _headGap;
    final maxBubbleWidth = (w - _horizontalPadding * 2).clamp(180.0, 320.0);

    return Positioned(
      left: _horizontalPadding,
      right: _horizontalPadding,
      bottom: bubbleBottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompanionSpeechBubble(
              text: text,
              palette: palette,
              maxWidth: maxBubbleWidth,
              showTail: false,
            ),
            if (showWriteStoryAction && onWriteStory != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onWriteStory,
                style: TextButton.styleFrom(
                  backgroundColor: palette.card.withValues(alpha: 0.92),
                  foregroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('去写今天的故事'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
