import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/growth/today_mood_display.dart';
import '../../core/theme/app_fonts.dart';

/// 岛屿下方的今日状态与升级进度（紧凑，避免挤出屏幕）。
class LandingIslandProgress extends StatelessWidget {
  const LandingIslandProgress({
    super.key,
    required this.summary,
    this.companionName,
    this.displayMoodId,
    this.progressBarHeight = 4,
  });

  final GrowthSummary summary;
  final String? companionName;
  /// 覆盖 [summary.todayMood] 的展示心情（引导页按「今日是否选过感受」解析）。
  final String? displayMoodId;
  final double progressBarHeight;

  @override
  Widget build(BuildContext context) {
    final weatherLabel = displayMoodId != null
        ? companionWeatherLabelForEmotionId(displayMoodId!)
        : summary.todayWeatherLabel;
    final statusLabel = summary.isGuest
        ? '今日 $weatherLabel'
        : GrowthSystem.todayCompanionStatusLabel(
            summary: summary,
            companionName: companionName ?? '小伙伴',
            weatherLabel: weatherLabel,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          statusLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5D4E44),
          ),
        ),
        const SizedBox(height: 10),
        if (!summary.isGuest) ...[
          Text(
            '成长值',
            textAlign: TextAlign.center,
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.levelProgressRatio,
              minHeight: progressBarHeight,
              backgroundColor: const Color(0xFFE8DDD4),
              color: const Color(0xFFE8A87C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.levelProgressPercent}%',
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C7B6B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.nextLevel == null
                ? '你已成为岛屿传说'
                : GrowthSystem.nextLevelDistanceLabel(summary),
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 12,
              height: 1.45,
              color: const Color(0xFF8C7B6B),
            ),
          ),
        ],
        if (summary.unlockLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            summary.unlockLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
        ],
      ],
    );
  }
}
