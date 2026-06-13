String _briefText(String text, [int maxLen = 30]) {
  final cleaned = text.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.length <= maxLen) return cleaned;
  return cleaned.substring(0, maxLen);
}

class DailyMoodReportModel {
  DailyMoodReportModel({
    required this.reportDate,
    required this.moodCounts,
    required this.radarScores,
    required this.momentCount,
    required this.insightSummary,
    required this.warmSuggestion,
    required this.concernLabel,
    required this.aiGenerated,
    required this.analysisSource,
    required this.uploadedAt,
    this.weeklyHint = '',
    this.weeklyTrendLabel = '',
    this.categoryFilter,
  });

  final String reportDate;
  final String? categoryFilter;
  final Map<String, int> moodCounts;
  final Map<String, double> radarScores;
  final int momentCount;
  final String insightSummary;
  final String warmSuggestion;
  final String concernLabel;
  final bool aiGenerated;
  final String analysisSource;
  final String uploadedAt;
  final String weeklyHint;
  final String weeklyTrendLabel;

  factory DailyMoodReportModel.fromJson(Map<String, dynamic> json) {
    return DailyMoodReportModel(
      reportDate: json['report_date'] as String? ?? '',
      categoryFilter: json['category_filter'] as String?,
      moodCounts: (json['mood_counts'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      radarScores: (json['radar_scores'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      momentCount: json['moment_count'] as int? ?? 0,
      insightSummary: (json['insight_summary'] as String? ??
              json['teacher_summary'] as String? ??
              '')
          .trim(),
      warmSuggestion: (json['warm_suggestion'] as String? ?? '').trim(),
      concernLabel: json['concern_label'] as String? ?? '状态平稳',
      aiGenerated: json['ai_generated'] as bool? ?? false,
      analysisSource: json['analysis_source'] as String? ?? 'unknown',
      uploadedAt: json['uploaded_at'] as String? ?? '',
      weeklyHint: _briefText(json['weekly_hint'] as String? ?? '', 50),
      weeklyTrendLabel: json['weekly_trend_label'] as String? ?? '',
    );
  }
}
