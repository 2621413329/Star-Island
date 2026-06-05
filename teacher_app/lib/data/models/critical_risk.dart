class CriticalRiskSignal {
  CriticalRiskSignal({
    required this.momentId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.reportDate,
    required this.categoryLabel,
    required this.storyDetail,
    required this.notePreview,
    required this.emotionTag,
    required this.riskReminder,
    required this.followUpStatus,
    this.followNote,
    this.followedAt,
  });

  final String momentId;
  final String studentId;
  final String studentName;
  final String className;
  final String reportDate;
  final String categoryLabel;
  final String storyDetail;
  final String notePreview;
  final String emotionTag;
  final String riskReminder;
  final String followUpStatus;
  final String? followNote;
  final DateTime? followedAt;

  bool get isFollowed => followUpStatus == 'followed';

  factory CriticalRiskSignal.fromJson(Map<String, dynamic> json) => CriticalRiskSignal(
        momentId: json['moment_id']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? '',
        studentName: json['student_name'] as String? ?? '学生',
        className: json['class_name'] as String? ?? '',
        reportDate: json['report_date'] as String? ?? '',
        categoryLabel: json['category_label'] as String? ?? '',
        storyDetail: json['story_detail'] as String? ?? '',
        notePreview: json['note_preview'] as String? ?? '',
        emotionTag: json['emotion_tag'] as String? ?? '',
        riskReminder: json['risk_reminder'] as String? ?? '',
        followUpStatus: json['follow_up_status'] as String? ?? 'pending',
        followNote: json['follow_note'] as String?,
        followedAt: json['followed_at'] != null ? DateTime.parse('${json['followed_at']}') : null,
      );
}

class CriticalRiskDetail {
  CriticalRiskDetail({
    required this.momentId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.reportDate,
    required this.emotionTag,
    required this.categoryLabel,
    required this.detailTags,
    required this.storyDetail,
    required this.note,
    required this.companionScene,
    required this.companionSceneLabel,
    required this.createdAt,
    required this.canDismiss,
    required this.riskReminder,
    required this.followUpStatus,
    this.followNote,
    this.followedAt,
  });

  final String momentId;
  final String studentId;
  final String studentName;
  final String className;
  final String reportDate;
  final String emotionTag;
  final String categoryLabel;
  final List<String> detailTags;
  final String storyDetail;
  final String note;
  final String companionScene;
  final String companionSceneLabel;
  final DateTime createdAt;
  final bool canDismiss;
  final String riskReminder;
  final String followUpStatus;
  final String? followNote;
  final DateTime? followedAt;

  bool get isFollowed => followUpStatus == 'followed';

  String get companionDisplay =>
      companionSceneLabel.isNotEmpty ? companionSceneLabel : companionScene;

  factory CriticalRiskDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['created_at'];
    return CriticalRiskDetail(
      momentId: json['moment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name'] as String? ?? '学生',
      className: json['class_name'] as String? ?? '',
      reportDate: json['report_date'] as String? ?? '',
      emotionTag: json['emotion_tag'] as String? ?? '',
      categoryLabel: json['category_label'] as String? ?? '',
      detailTags: (json['detail_tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      storyDetail: json['story_detail'] as String? ?? '',
      note: json['note'] as String? ?? '',
      companionScene: json['companion_scene'] as String? ?? '',
      companionSceneLabel: json['companion_scene_label'] as String? ?? '',
      createdAt: raw is String ? DateTime.parse(raw) : DateTime.now(),
      canDismiss: json['can_dismiss'] as bool? ?? true,
      riskReminder: json['risk_reminder'] as String? ?? '',
      followUpStatus: json['follow_up_status'] as String? ?? 'pending',
      followNote: json['follow_note'] as String?,
      followedAt: json['followed_at'] != null ? DateTime.parse('${json['followed_at']}') : null,
    );
  }
}

class DangerSignalRecord {
  DangerSignalRecord({
    required this.momentId,
    required this.date,
    this.categoryTag,
    required this.categoryLabel,
    required this.storyDetail,
    required this.note,
    required this.emotionTag,
    this.canDismiss = true,
  });

  final String momentId;
  final String date;
  final String? categoryTag;
  final String categoryLabel;
  final String storyDetail;
  final String note;
  final String emotionTag;
  final bool canDismiss;

  factory DangerSignalRecord.fromJson(Map<String, dynamic> json) => DangerSignalRecord(
        momentId: json['moment_id']?.toString() ?? '',
        date: json['date'] as String? ?? '',
        categoryTag: json['category_tag'] as String?,
        categoryLabel: json['category_label'] as String? ?? '',
        storyDetail: json['story_detail'] as String? ?? '',
        note: json['note'] as String? ?? '',
        emotionTag: json['emotion_tag'] as String? ?? '',
        canDismiss: json['can_dismiss'] as bool? ?? true,
      );
}
