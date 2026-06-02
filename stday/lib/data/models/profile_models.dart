import '../../core/models/companion_spec.dart';

class UserProfileModel {
  UserProfileModel({
    required this.userId,
    required this.onboardingCompleted,
    this.studentId,
    this.gender,
    this.companionStyle,
    this.todayMood,
  });

  final String userId;
  final String? studentId;
  final String? gender;
  final String? companionStyle;
  final String? todayMood;
  final bool onboardingCompleted;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: '${json['user_id']}',
      studentId: json['student_id'] != null ? '${json['student_id']}' : null,
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
    this.note,
    this.visualPayload = const {},
  });

  final String id;
  final List<String> eventTags;
  final String emotionTag;
  final String? note;
  final String companionScene;
  final String companionPose;
  final Map<String, dynamic> visualPayload;

  String get actionType =>
      visualPayload['animation_type'] as String? ??
      visualPayload['action_type'] as String? ??
      'wave';

  CompanionSpec get companionSpec => CompanionSpec.fromPayload(visualPayload, fallbackMood: emotionTag);

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
      visualPayload: json['visual_payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

class AuthEntryResult {
  AuthEntryResult({required this.accessToken, required this.isNewUser});
  final String accessToken;
  final bool isNewUser;
}
