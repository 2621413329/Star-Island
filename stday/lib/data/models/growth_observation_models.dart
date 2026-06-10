class StudentGrowthObservation {
  StudentGrowthObservation({
    required this.weeklyHint,
    required this.trendLabel,
    required this.stressDirections,
    required this.disclaimer,
  });

  final String weeklyHint;
  final String trendLabel;
  final List<String> stressDirections;
  final String disclaimer;

  factory StudentGrowthObservation.fromJson(Map<String, dynamic> json) {
    return StudentGrowthObservation(
      weeklyHint: json['weekly_hint'] as String? ?? '',
      trendLabel: json['trend_label'] as String? ?? '稳定',
      stressDirections:
          (json['stress_directions'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
