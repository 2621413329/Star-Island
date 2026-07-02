import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../design_system/companion_write_avatar.dart';
import '../../../design_system/healing_jelly_button.dart';
import '../../../design_system/home_theme.dart';
import '../../../providers/app_providers.dart';

class StoryEntryCard extends ConsumerWidget {
  const StoryEntryCard({super.key, required this.onStartRecording});

  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companion = ref.watch(userCompanionProvider);
    final palette = ref.watch(moodPaletteProvider);
    final tone = HealingJellyTone.fromPalette(palette);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        boxShadow: const [HomeTheme.cardShadow],
      ),
      child: HealingSparkleBackground(
        tone: tone,
        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompanionWriteAvatar(
              companion: companion,
              size: 56,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '记录今天的故事',
                    style: appTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HomeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI 将帮你放入合适的位置',
                    style: appTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: HomeTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            HealingJellyCircleButton(
              onPressed: onStartRecording,
              tone: tone,
              size: 72,
              semanticLabel: '开始记录今天的故事',
            ),
          ],
        ),
      ),
    );
  }
}
