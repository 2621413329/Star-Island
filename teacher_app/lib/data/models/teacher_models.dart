import 'growth_observation.dart';

class AuthToken {
  AuthToken({required this.accessToken});
  final String accessToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      AuthToken(accessToken: json['access_token'] as String? ?? '');
}

class TeacherProfile {
  TeacherProfile({
    required this.username,
    required this.nickname,
    required this.className,
  });

  final String username;
  final String nickname;
  final String className;

  factory TeacherProfile.fromJson(Map<String, dynamic> json) => TeacherProfile(
        username: json['username'] as String? ?? '',
        nickname: json['nickname'] as String? ?? json['username'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
      );
}

class TeacherMoodReport {
  TeacherMoodReport({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.reportDate,
    required this.moodCounts,
    required this.teacherRadarScores,
    required this.categoryBreakdown,
    required this.momentCount,
    required this.concernLevel,
    required this.concernLabel,
    required this.riskFlags,
    required this.attentionHighlights,
    required this.fuzzyAnalysis,
    required this.uploadedAt,
    this.riskExposures = const [],
  });

  final String? studentId;
  final String? studentName;
  final String? className;
  final String reportDate;
  final Map<String, int> moodCounts;
  final Map<String, double> teacherRadarScores;
  final Map<String, int> categoryBreakdown;
  final int momentCount;
  final String concernLevel;
  final String concernLabel;
  final List<String> riskFlags;
  final List<String> attentionHighlights;
  final String fuzzyAnalysis;
  final DateTime? uploadedAt;
  final List<RiskExposure> riskExposures;

  factory TeacherMoodReport.fromJson(Map<String, dynamic> json) {
    DateTime? uploaded;
    final raw = json['uploaded_at'];
    if (raw is String) {
      uploaded = DateTime.tryParse(raw);
    }
    return TeacherMoodReport(
      studentId: json['student_id'] as String?,
      studentName: json['student_name'] as String?,
      className: json['class_name'] as String?,
      reportDate: json['report_date'] as String? ?? '',
      moodCounts: (json['mood_counts'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      teacherRadarScores: (json['teacher_radar_scores'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      categoryBreakdown: (json['category_breakdown'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      momentCount: json['moment_count'] as int? ?? 0,
      concernLevel: json['concern_level'] as String? ?? 'normal',
      concernLabel: json['concern_label'] as String? ?? '状态平稳',
      riskFlags: (json['risk_flags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      attentionHighlights:
          (json['attention_highlights'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      fuzzyAnalysis: json['fuzzy_analysis'] as String? ?? '',
      uploadedAt: uploaded,
      riskExposures: (json['risk_exposures'] as List<dynamic>? ?? [])
          .map((e) => RiskExposure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherAlert {
  TeacherAlert({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.alertType,
    required this.title,
    required this.summary,
    required this.status,
    required this.priority,
    this.reportDate,
    this.dateEnd,
    this.ackedAt,
  });

  final String id;
  final String studentId;
  final String? studentName;
  final String? className;
  final String alertType;
  final String title;
  final String summary;
  final String status;
  final int priority;
  final String? reportDate;
  final String? dateEnd;
  final DateTime? ackedAt;

  bool get isPending => status == 'pending';
  bool get isAcked => status == 'acked';

  /// 查看心情时优先用报告日，连续低落则用区间结束日。
  String get moodLookupDate => reportDate ?? dateEnd ?? '';

  factory TeacherAlert.fromJson(Map<String, dynamic> json) {
    DateTime? acked;
    final raw = json['acked_at'];
    if (raw is String) acked = DateTime.tryParse(raw);
    return TeacherAlert(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String?,
      className: json['class_name'] as String?,
      alertType: json['alert_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as int? ?? 0,
      reportDate: json['report_date'] as String?,
      dateEnd: json['date_end'] as String?,
      ackedAt: acked,
    );
  }
}
