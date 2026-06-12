import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../data/models/mood_report_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/growth_observation_provider.dart';
import '../../providers/mood_report_check_in_provider.dart';

Future<void> uploadAndShowDailyMoodReport({
  required BuildContext context,
  required WidgetRef ref,
  String? categoryFilter,
}) async {
  try {
    final report =
        await ref.read(appRepositoryProvider).uploadDailyMoodReport(
              categoryFilter: categoryFilter,
            );
    if (!context.mounted) return;
    ref.invalidate(moodReportCheckInProvider);
    ref.invalidate(studentGrowthObservationProvider);
    await showDailyMoodReportResultDialog(context, ref, report: report);
  } catch (e) {
    if (!context.mounted) return;
    final message = e is ApiException
        ? e.message
        : '整理失败，请确认后端已启动并重试';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

Future<void> showDailyMoodReportResultDialog(
  BuildContext context,
  WidgetRef ref, {
  required DailyMoodReportModel report,
}) {
  final palette = ref.read(moodPaletteProvider);
  final insight = report.insightSummary;
  final warm = report.warmSuggestion;
  final concern = report.concernLabel;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '今日心情已整理好了',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                concern,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              insight,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
            if (warm.isNotEmpty && warm != insight) ...[
              const SizedBox(height: 8),
              Text(
                warm,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (report.weeklyHint.isNotEmpty &&
                report.weeklyHint != insight &&
                report.weeklyHint != warm) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    if (report.weeklyTrendLabel.isNotEmpty &&
                        report.weeklyTrendLabel != '稳定')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '本周趋势 · ${report.weeklyTrendLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    Text(
                      report.weeklyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '老师端只会看到统计概览，你的故事原文不会展示',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom(foregroundColor: palette.accent),
          child: const Text('好的'),
        ),
      ],
    ),
  );
}
