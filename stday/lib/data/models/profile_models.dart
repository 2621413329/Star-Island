import '../../core/growth/growth_system.dart';
import '../../core/models/companion_spec.dart';

class EmotionFragmentSummary {
  const EmotionFragmentSummary({
    required this.totalCount,
    required this.totals,
  });

  final int totalCount;
  final Map<String, int> totals;

  factory EmotionFragmentSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['totals'];
    final totals = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        totals['$key'] = value is int ? value : int.tryParse('$value') ?? 0;
      });
    }
    return EmotionFragmentSummary(
      totalCount: json['total_count'] as int? ?? 0,
      totals: totals,
    );
  }
}

class UserProfileModel {
  UserProfileModel({
    required this.userId,
    required this.onboardingCompleted,
    this.studentId,
    this.nickname,
    this.gender,
    this.companionStyle,
    this.todayMood,
    this.growth,
    this.emotionFragments,
    this.appPreferences = const {},
  });

  final String userId;
  final String? studentId;
  final String? nickname;
  final String? gender;
  final String? companionStyle;
  final String? todayMood;
  final bool onboardingCompleted;
  final Map<String, dynamic> appPreferences;
  final GrowthSummary? growth;
  final EmotionFragmentSummary? emotionFragments;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: '${json['user_id']}',
      studentId: json['student_id'] != null ? '${json['student_id']}' : null,
      nickname: json['nickname'] as String?,
      gender: json['gender'] as String?,
      companionStyle: json['companion_style'] as String?,
      todayMood: json['today_mood'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      appPreferences: json['app_preferences'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['app_preferences'] as Map)
          : const {},
      growth: json['growth'] is Map<String, dynamic>
          ? GrowthSummary.fromJson(json['growth'] as Map<String, dynamic>)
          : null,
      emotionFragments: json['emotion_fragments'] is Map<String, dynamic>
          ? EmotionFragmentSummary.fromJson(
              json['emotion_fragments'] as Map<String, dynamic>,
            )
          : null,
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
    this.clientEventId,
    this.note,
    this.visualPayload = const {},
  });

  final String id;
  final List<String> eventTags;
  final String emotionTag;
  final String? note;
  final String? clientEventId;
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

  /// 故事总结话语（生成时固定 3 条，详情页点击小人随机展示其一）。
  List<String> get storySummaryLines {
    final raw = visualPayload['story_summary_lines'];
    if (raw is List) {
      final lines =
          raw.map((e) => '$e'.trim()).where((line) => line.isNotEmpty).toList();
      if (lines.isNotEmpty) return lines;
    }
    if (note != null && note!.trim().isNotEmpty) {
      final snippet = note!.trim();
      final clipped =
          snippet.length > 24 ? '${snippet.substring(0, 24)}…' : snippet;
      return [
        '我记得你说：$clipped',
        '这一刻的心情，小岛替你收好了',
        '每次点我，我都会陪你回味这件事',
      ];
    }
    if (eventTags.isNotEmpty) {
      final tagLine = eventTags.where((t) => t != '自定义').join(' · ');
      return [
        '关于$tagLine的这件事，值得被记住',
        '当时的心情，我都替你收在小岛上了',
        '点我，我会用不同的话陪你回味',
      ];
    }
    return const [
      '这一刻的心情，小岛替你收好了',
      '每次点我，我都会陪你回味这件事',
      '你的故事，值得被温柔记住',
    ];
  }

  String? get performanceHint => visualPayload['performance_hint'] as String?;

  factory DailyMomentModel.fromJson(Map<String, dynamic> json) {
    return DailyMomentModel(
      id: '${json['id']}',
      eventTags: (json['event_tags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      emotionTag: json['emotion_tag'] as String,
      clientEventId: json['client_event_id'] as String?,
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
    final dateOnly =
        DateTime.tryParse(text.length <= 10 ? '${text}T00:00:00' : text);
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
