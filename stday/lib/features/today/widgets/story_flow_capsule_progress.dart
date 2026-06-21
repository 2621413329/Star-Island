import 'package:flutter/material.dart';

import '../../../core/theme/mood_theme.dart';

/// 写日常流程胶囊进度条：线性填充 + 左右滑动切换步骤。
class StoryFlowCapsuleProgress extends StatelessWidget {
  const StoryFlowCapsuleProgress({
    super.key,
    required this.progress,
    required this.stepIndex,
    required this.stepCount,
    required this.stepTitle,
    required this.palette,
    this.onSwipeBack,
    this.onSwipeForward,
    this.canSwipeBack = true,
    this.canSwipeForward = false,
  });

  final double progress;
  final int stepIndex;
  final int stepCount;
  final String stepTitle;
  final MoodPalette palette;
  final VoidCallback? onSwipeBack;
  final VoidCallback? onSwipeForward;
  final bool canSwipeBack;
  final bool canSwipeForward;

  static const _trackColor = Color(0xFFE9E5E0);
  static const _fillColor = Color(0xFF9BA8B4);

  @override
  Widget build(BuildContext context) {
    final fill = progress.clamp(0.08, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 280) return;
        if (velocity > 0) {
          if (canSwipeBack) onSwipeBack?.call();
        } else {
          if (canSwipeForward) onSwipeForward?.call();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '第 ${stepIndex + 1} / $stepCount 步',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.primary.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                Text(
                  stepTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.primary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SizedBox(
                  height: 10,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        width: width,
                        decoration: BoxDecoration(
                          color: _trackColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: width * fill,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _fillColor,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: _fillColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              '左右滑动可返回上一步或进入下一步',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: palette.primary.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
