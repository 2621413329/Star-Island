import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../core/utils/mood_period.dart';
import '../../../data/models/mood_report_models.dart';
import '../../../design_system/island_decorations.dart';

/// 心情概览 Tab 内：当前筛选周期下所有 AI 心情总结。
class MoodSummarySection extends StatelessWidget {
  const MoodSummarySection({
    super.key,
    required this.palette,
    required this.period,
    required this.reports,
  });

  final MoodPalette palette;
  final MoodStatusPeriod period;
  final List<DailyMoodReportModel> reports;

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyMoodReportModel>.from(reports)
      ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

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
          '${period.label} · 共 ${sorted.length} 份 AI 总结',
          style: TextStyle(
            fontSize: 12,
            color: palette.primary.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        if (sorted.isEmpty)
          IslandGlassCard(
            palette: palette,
            padding: const EdgeInsets.all(16),
            child: Text(
              '${period.label}还没有心情 AI 总结\n记录故事并上传心情报告后会出现在这里',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: palette.primary.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ...sorted.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MoodSummaryCard(
                palette: palette,
                report: r,
              ),
            ),
          ),
      ],
    );
  }
}

class _MoodSummaryCard extends StatelessWidget {
  const _MoodSummaryCard({
    required this.palette,
    required this.report,
  });

  final MoodPalette palette;
  final DailyMoodReportModel report;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatReportDate(report.reportDate);
    final insight = report.insightSummary.trim();
    final suggestion = report.warmSuggestion.trim();

    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              if (report.aiGenerated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer.withValues(alpha: 0.5),
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
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              insight,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: palette.primary,
              ),
            ),
          ],
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              suggestion,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: palette.primary.withValues(alpha: 0.72),
              ),
            ),
          ],
          if (insight.isEmpty && suggestion.isEmpty)
            Text(
              '暂无文字总结',
              style: TextStyle(
                fontSize: 13,
                color: palette.primary.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatReportDate(String iso) {
  final parsed = DateTime.tryParse('${iso}T00:00:00') ??
      DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(parsed.year, parsed.month, parsed.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (parsed.year == now.year) {
    return DateFormat('M月d日', 'zh_CN').format(parsed);
  }
  return DateFormat('yyyy年M月d日', 'zh_CN').format(parsed);
}
