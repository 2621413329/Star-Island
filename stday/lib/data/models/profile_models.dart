import '../../core/models/companion_spec.dart';

class UserProfileModel {
  UserProfileModel({
    required this.userId,
    required this.onboardingCompleted,
    this.studentId,
    this.nickname,
    this.gender,
    this.companionStyle,
    this.todayMood,
  });

  final String userId;
  final String? studentId;
  final String? nickname;
  final String? gender;
  final String? companionStyle;
  final String? todayMood;
  final bool onboardingCompleted;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: '${json['user_id']}',
      studentId: json['student_id'] != null ? '${json['student_id']}' : null,
      nickname: json['nickname'] as String?,
      gender: json['gender'] as String?,
      companionStyle: json['companion_style'] as String?,
      todayMood: json['today_mood'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }
}

class DailyMomentModel {
  DailyMomentModel({
    required this.id,
    required this.eventTags,
    required this.emotionTag,
    required this.companionScene,
    required this.companionPose,
    required this.momentDate,
    required this.createdAt,
    this.note,
    this.visualPayload = const {},
  });

  final String id;
  final List<String> eventTags;
  final String emotionTag;
  final String? note;
  final String companionScene;
  final String companionPose;
  final DateTime momentDate;
  final DateTime createdAt;
  final Map<String, dynamic> visualPayload;

  String get actionType =>
      visualPayload['animation_type'] as String? ??
      visualPayload['action_type'] as String? ??
      'wave';

  CompanionSpec get companionSpec {
    final payload = Map<String, dynamic>.from(visualPayload);
    payload['event_tags'] = eventTags;
    payload['note_hint'] = note;
    payload['emotion_tag'] = emotionTag;
    return CompanionSpec.fromPayload(payload, fallbackMood: emotionTag);
  }

  String? get sceneTitle => visualPayload['scene_title'] as String?;

  List<String> get waitingLines {
    final raw = visualPayload['waiting_lines'];
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  String? get performanceHint => visualPayload['performance_hint'] as String?;

  factory DailyMomentModel.fromJson(Map<String, dynamic> json) {
    return DailyMomentModel(
      id: '${json['id']}',
      eventTags: (json['event_tags'] as List<dynamic>).map((e) => e as String).toList(),
      emotionTag: json['emotion_tag'] as String,
      note: json['note'] as String?,
      companionScene: json['companion_scene'] as String,
      companionPose: json['companion_pose'] as String? ?? 'breathing',
      momentDate: _parseDate(json['moment_date']),
      createdAt: _parseDateTime(json['created_at']),
      visualPayload: json['visual_payload'] as Map<String, dynamic>? ?? {},
    );
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final text = '$raw';
    final dateOnly = DateTime.tryParse(text.length <= 10 ? '${text}T00:00:00' : text);
    return dateOnly ?? DateTime.now();
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return DateTime.now();
    return parsed.toLocal();
  }
}

class AuthEntryResult {
  AuthEntryResult({required this.accessToken, required this.isNewUser});
  final String accessToken;
  final bool isNewUser;
}
