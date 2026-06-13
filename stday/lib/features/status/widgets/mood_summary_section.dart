import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_period.dart';
import '../../../data/models/mood_report_models.dart';
import '../../../design_system/island_decorations.dart';

/// 心情概览 Tab 内：当前筛选周期下的总体 AI 心情总结（≤100字）。
class MoodSummarySection extends StatelessWidget {
  const MoodSummarySection({
    super.key,
    required this.palette,
    required this.period,
    required this.summaryAsync,
  });

  final MoodPalette palette;
  final MoodStatusPeriod period;
  final AsyncValue<MoodPeriodSummaryModel> summaryAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '心情总结',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${period.label} · 总体概览',
          style: TextStyle(
            fontSize: 12,
            color: palette.primary.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        summaryAsync.when(
          loading: () => IslandGlassCard(
            palette: palette,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '正在生成${period.label}心情总结…',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.primary.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          error: (_, __) => IslandGlassCard(
            palette: palette,
            padding: const EdgeInsets.all(16),
            child: Text(
              '暂时无法生成${period.label}总结，请稍后下拉刷新',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: palette.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          data: (summary) {
            if (summary.summary.isEmpty) {
              return IslandGlassCard(
                palette: palette,
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${period.label}还没有心情记录\n记下故事后这里会出现总体总结',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: palette.primary.withValues(alpha: 0.6),
                  ),
                ),
              );
            }
            return IslandGlassCard(
              palette: palette,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${period.label}总结',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                      const Spacer(),
                      if (summary.aiGenerated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: palette.primary.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.summary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: palette.primary,
                    ),
                  ),
                  if (summary.totalMoments > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '基于 ${summary.totalMoments} 条心情记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
