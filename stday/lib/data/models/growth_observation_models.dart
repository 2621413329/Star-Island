class WeeklySummary {
  WeeklySummary({
    required this.weeklyHint,
    required this.trendLabel,
    required this.disclaimer,
  });

  final String weeklyHint;
  final String trendLabel;
  final String disclaimer;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      weeklyHint: json['weekly_hint'] as String? ?? '',
      trendLabel: json['trend_label'] as String? ?? '稳定',
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
