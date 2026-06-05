import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/theme/app_fonts.dart';

/// 岛屿下方的今日状态与升级进度（紧凑，避免挤出屏幕）。
class LandingIslandProgress extends StatelessWidget {
  const LandingIslandProgress({
    super.key,
    required this.summary,
    this.progressBarHeight = 4,
  });

  final GrowthSummary summary;
  final double progressBarHeight;

  @override
  Widget build(BuildContext context) {
    final next = summary.nextLevel;
    final need = summary.xpForNextLevel;
    final progressText = _progressLabel(summary, next, need);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '今日 ${summary.todayWeatherLabel}',
          textAlign: TextAlign.center,
          style: appTextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF5D4E44)),
        ),
        const SizedBox(height: 4),
        Text(
          progressText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: appTextStyle(fontSize: 12, color: const Color(0xFF8C7B6B)),
        ),
        if (need != null && need > 0 && next != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.xpIntoLevel / need).clamp(0.0, 1.0),
              minHeight: progressBarHeight,
              backgroundColor: const Color(0xFFE8DDD4),
              color: const Color(0xFFE8A87C),
            ),
          ),
        ],
        if (summary.unlockLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            summary.unlockLabel,
            textAlign: TextAlign.center,
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
        ],
      ],
    );
  }

  static String _progressLabel(GrowthSummary summary, int? next, int? need) {
    if (next != null && need != null && need > 0) {
      final remaining = (need - summary.xpIntoLevel).clamp(0, need);
      if (summary.growthValue == 0 && summary.level <= 1) {
        return '成长刚刚开始';
      }
      return '距离 Lv.$next 还需 $remaining 成长值';
    }
    if (summary.level >= 10) {
      return '你已走过完整的成长旅程';
    }
    return '成长刚刚开始';
  }
}
