import 'critical_risk.dart';

class GrowthInsight {
  GrowthInsight({
    required this.status,
    required this.focusTags,
    required this.focusDirections,
    required this.trend,
    required this.summary,
    required this.needAttention,
    required this.riskLevel,
    this.riskReminder,
  });

  final String status;
  final List<String> focusTags;
  final List<String> focusDirections;
  final String trend;
  final String summary;
  final bool needAttention;
  final String riskLevel;
  final String? riskReminder;

  factory GrowthInsight.fromJson(Map<String, dynamic> json) => GrowthInsight(
        status: json['status'] as String? ?? 'observing',
        focusTags: (json['focus_tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
        focusDirections:
            (json['focus_directions'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
        trend: json['trend'] as String? ?? 'stable',
        summary: json['summary'] as String? ?? '',
        needAttention: json['need_attention'] as bool? ?? false,
        riskLevel: json['risk_level'] as String? ?? 'none',
        riskReminder: json['risk_reminder'] as String?,
      );
}

class GrowthFocusItem {
  GrowthFocusItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.reportDate,
    required this.dateEnd,
    required this.title,
    required this.growthStatus,
    required this.summary,
    required this.focusDirections,
    required this.focusTags,
    required this.trend,
    required this.needAttention,
    required this.riskLevel,
    required this.followUpStatus,
    this.riskReminder,
    this.ackedAt,
  });

  final String id;
  final String studentId;
  final String? studentName;
  final String? className;
  final String? reportDate;
  final String dateEnd;
  final String title;
  final String growthStatus;
  final String summary;
  final List<String> focusDirections;
  final List<String> focusTags;
  final String trend;
  final bool needAttention;
  final String riskLevel;
  final String? riskReminder;
  final String followUpStatus;
  final DateTime? ackedAt;

  bool get isFollowed => followUpStatus == 'followed';
  bool get isCritical => riskLevel == 'critical';

  String get moodLookupDate => reportDate ?? dateEnd;

  factory GrowthFocusItem.fromJson(Map<String, dynamic> json) {
    DateTime? acked;
    final raw = json['acked_at'];
    if (raw is String) acked = DateTime.tryParse(raw);
    return GrowthFocusItem(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String?,
      className: json['class_name'] as String?,
      reportDate: json['report_date'] as String?,
      dateEnd: json['date_end'] as String? ?? '',
      title: json['title'] as String? ?? '成长关注',
      growthStatus: json['growth_status'] as String? ?? 'ongoing',
      summary: json['summary'] as String? ?? '',
      focusDirections:
          (json['focus_directions'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      focusTags: (json['focus_tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      trend: json['trend'] as String? ?? 'stable',
      needAttention: json['need_attention'] as bool? ?? false,
      riskLevel: json['risk_level'] as String? ?? 'none',
      riskReminder: json['risk_reminder'] as String?,
      followUpStatus: json['follow_up_status'] as String? ?? 'pending',
      ackedAt: acked,
    );
  }
}

class AttentionTag {
  AttentionTag({required this.code, required this.label, required this.count});
  final String code;
  final String label;
  final int count;

  factory AttentionTag.fromJson(Map<String, dynamic> json) => AttentionTag(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 1,
      );
}

class TrendPoint {
  TrendPoint({required this.date, required this.moodScore, required this.recordCount});
  final String date;
  final double moodScore;
  final int recordCount;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: json['date'] as String? ?? '',
        moodScore: (json['mood_score'] as num?)?.toDouble() ?? 0,
        recordCount: json['record_count'] as int? ?? 0,
      );
}

class GrowthTimelineItem {
  GrowthTimelineItem({
    this.momentId,
    required this.date,
    required this.emotionTag,
    this.categoryTag,
    this.categoryLabel,
    this.note,
    this.noteExposed = false,
    this.canDismiss = false,
    required this.aiTags,
  });

  final String? momentId;
  final String date;
  final String emotionTag;
  final String? categoryTag;
  final String? categoryLabel;
  final String? note;
  final bool noteExposed;
  final bool canDismiss;
  final List<String> aiTags;

  factory GrowthTimelineItem.fromJson(Map<String, dynamic> json) => GrowthTimelineItem(
        momentId: json['moment_id']?.toString(),
        date: json['date'] as String? ?? '',
        emotionTag: json['emotion_tag'] as String? ?? '',
        categoryTag: json['category_tag'] as String?,
        categoryLabel: json['category_label'] as String?,
        note: json['note'] as String?,
        noteExposed: json['note_exposed'] as bool? ?? false,
        canDismiss: json['can_dismiss'] as bool? ?? false,
        aiTags: (json['ai_tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      );
}

class RiskExposure {
  RiskExposure({
    required this.momentId,
    required this.date,
    required this.emotionTag,
    required this.note,
    this.canDismiss = true,
  });

  final String momentId;
  final String date;
  final String emotionTag;
  final String note;
  final bool canDismiss;

  factory RiskExposure.fromJson(Map<String, dynamic> json) => RiskExposure(
        momentId: json['moment_id']?.toString() ?? '',
        date: json['date'] as String? ?? '',
        emotionTag: json['emotion_tag'] as String? ?? '',
        note: json['note'] as String? ?? '',
        canDismiss: json['can_dismiss'] as bool? ?? true,
      );
}

class TeacherFollowUp {
  TeacherFollowUp({required this.id, required this.action, this.note, required this.createdAt});
  final String id;
  final String action;
  final String? note;
  final DateTime createdAt;

  factory TeacherFollowUp.fromJson(Map<String, dynamic> json) {
    final raw = json['created_at'];
    return TeacherFollowUp(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: raw is String ? DateTime.parse(raw) : DateTime.now(),
    );
  }
}

class GrowthDayRecord {
  GrowthDayRecord({
    required this.date,
    required this.aiSummary,
    required this.insight,
    required this.momentCount,
    required this.moodCounts,
    required this.categoryBreakdown,
    this.moodScore,
    this.hasReport = false,
    this.dangerRecords = const [],
    this.entries = const [],
  });

  final String date;
  final String aiSummary;
  final GrowthInsight insight;
  final int momentCount;
  final Map<String, int> moodCounts;
  final Map<String, int> categoryBreakdown;
  final double? moodScore;
  final bool hasReport;
  final List<DangerSignalRecord> dangerRecords;
  final List<GrowthTimelineItem> entries;

  factory GrowthDayRecord.fromJson(Map<String, dynamic> json) => GrowthDayRecord(
        date: json['date'] as String? ?? '',
        aiSummary: json['ai_summary'] as String? ?? '',
        insight: GrowthInsight.fromJson(json['insight'] as Map<String, dynamic>? ?? {}),
        momentCount: json['moment_count'] as int? ?? 0,
        moodCounts: (json['mood_counts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        categoryBreakdown: (json['category_breakdown'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        moodScore: (json['mood_score'] as num?)?.toDouble(),
        hasReport: json['has_report'] as bool? ?? false,
        dangerRecords: (json['danger_records'] as List<dynamic>? ??
                json['entries'] as List<dynamic>? ??
                [])
            .map((e) => DangerSignalRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => GrowthTimelineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GrowthArchive {
  GrowthArchive({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.aiSummary,
    required this.insight,
    this.trendMetricLabel = '',
    required this.trendPoints,
    required this.moodCounts,
    required this.categoryBreakdown,
    this.moodCountsByCategory = const {},
    required this.attentionTags,
    this.dailyRecords = const [],
    this.timeline = const [],
    this.riskExposures = const [],
    this.followUps = const [],
  });

  final String studentId;
  final String studentName;
  final String className;
  final String aiSummary;
  final GrowthInsight insight;
  final String trendMetricLabel;
  final List<TrendPoint> trendPoints;
  final Map<String, int> moodCounts;
  final Map<String, int> categoryBreakdown;
  final Map<String, Map<String, int>> moodCountsByCategory;
  final List<AttentionTag> attentionTags;
  final List<GrowthDayRecord> dailyRecords;
  final List<GrowthTimelineItem> timeline;
  final List<RiskExposure> riskExposures;
  final List<TeacherFollowUp> followUps;

  factory GrowthArchive.fromJson(Map<String, dynamic> json) => GrowthArchive(
        studentId: json['student_id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
        aiSummary: json['ai_summary'] as String? ?? '',
        insight: GrowthInsight.fromJson(json['insight'] as Map<String, dynamic>? ?? {}),
        trendMetricLabel: json['trend_metric_label'] as String? ?? '',
        trendPoints: (json['trend_points'] as List<dynamic>? ?? [])
            .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        moodCounts: (json['mood_counts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        categoryBreakdown: (json['category_breakdown'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        moodCountsByCategory: _parseMoodCountsByCategory(json['mood_counts_by_category']),
        attentionTags: (json['attention_tags'] as List<dynamic>? ?? [])
            .map((e) => AttentionTag.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyRecords: (json['daily_records'] as List<dynamic>? ?? [])
            .map((e) => GrowthDayRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((e) => GrowthTimelineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        riskExposures: (json['risk_exposures'] as List<dynamic>? ?? [])
            .map((e) => RiskExposure.fromJson(e as Map<String, dynamic>))
            .toList(),
        followUps: (json['follow_ups'] as List<dynamic>? ?? [])
            .map((e) => TeacherFollowUp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

Map<String, Map<String, int>> _parseMoodCountsByCategory(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((catKey, catVal) {
    if (catVal is! Map) return MapEntry('$catKey', <String, int>{});
    return MapEntry(
      '$catKey',
      catVal.map((k, v) => MapEntry('$k', (v as num).toInt())),
    );
  });
}

String growthStatusLabel(String status) {
  switch (status) {
    case 'priority':
      return '优先关注';
    case 'ongoing':
      return '持续关注';
    default:
      return '观察中';
  }
}

String followUpActionLabel(String action) {
  switch (action) {
    case 'communicated':
      return '已沟通';
    case 'contacted_parent':
      return '已联系家长';
    case 'referred_counselor':
      return '已转心理老师';
    default:
      return '持续观察';
  }
}

String trendLabel(String trend) {
  switch (trend) {
    case 'up':
      return '上升';
    case 'down':
      return '下降';
    default:
      return '稳定';
  }
}
