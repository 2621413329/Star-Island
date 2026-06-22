import 'package:flutter/material.dart';

import '../../core/growth/growth_system.dart';
import '../../core/theme/app_fonts.dart';

/// 成长等级与进度展示（百分比 + 下一级提示，不暴露原始分数分子分母）。
class GrowthLevelProgressView extends StatelessWidget {
  const GrowthLevelProgressView({
    super.key,
    required this.summary,
    this.progressBarHeight = 6,
    this.showLevelHeader = true,
    this.showGrowthValueLabel = true,
    this.compact = false,
  });

  final GrowthSummary summary;
  final double progressBarHeight;
  final bool showLevelHeader;
  final bool showGrowthValueLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (summary.isGuest) {
      return Text(
        '登录后开始记录你的成长',
        textAlign: TextAlign.center,
        style: appTextStyle(fontSize: 12, color: const Color(0xFF8C7B6B)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLevelHeader) ...[
          Text(
            GrowthSystem.levelDisplayLabel(summary),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appTextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (showGrowthValueLabel) ...[
          Text(
            '成长值',
            style: appTextStyle(
              fontSize: 12,
              color: const Color(0xFF8C7B6B),
            ),
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(progressBarHeight / 2),
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
          textAlign: compact ? TextAlign.center : TextAlign.end,
          style: appTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8C7B6B),
          ),
        ),
        if (summary.nextLevel != null) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            GrowthSystem.nextLevelDistanceLabel(summary),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: appTextStyle(
              fontSize: compact ? 11 : 12,
              height: 1.45,
              color: const Color(0xFF5D4E44),
            ),
          ),
        ] else ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            '你已成为岛屿传说',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: appTextStyle(
              fontSize: compact ? 11 : 12,
              color: const Color(0xFF5D4E44),
            ),
          ),
        ],
      ],
    );
  }
}
