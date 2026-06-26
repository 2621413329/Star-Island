import '../../core/growth/growth_system.dart';
import '../../core/models/companion_spec.dart';
import '../../core/utils/companion_dialogue.dart';
import '../../core/utils/moment_tags.dart';

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
    this.nickname,
    this.gender,
    this.companionRoleId,
    this.companionStyle,
    this.todayMood,
    this.growth,
    this.emotionFragments,
    this.appPreferences = const {},
  });

  final String userId;
  final String? nickname;
  final String? gender;
  final String? companionRoleId;
  final String? companionStyle;
  final String? todayMood;
  final bool onboardingCompleted;
  final Map<String, dynamic> appPreferences;
  final GrowthSummary? growth;
  final EmotionFragmentSummary? emotionFragments;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: '${json['user_id']}',
      nickname: json['nickname'] as String?,
      gender: json['gender'] as String?,
      companionRoleId: json['companion_role_id'] as String?,
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

class MomentPhotoModel {
  const MomentPhotoModel({
    required this.id,
    required this.filename,
    required this.urlPath,
    this.contentType,
    this.sizeBytes,
    this.createdAt,
  });

  final String id;
  final String filename;
  final String urlPath;
  final String? contentType;
  final int? sizeBytes;
  final String? createdAt;

  factory MomentPhotoModel.fromJson(Map<String, dynamic> json) {
    return MomentPhotoModel(
      id: '${json['id']}',
      filename: json['filename'] as String? ?? '',
      urlPath: json['url_path'] as String? ?? '',
      contentType: json['content_type'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class DailyMomentModel {
  DailyMomentModel({
    required this.id,
    required this.eventTags,
    required this.emotionTag,
    this.primaryTag,
    this.secondaryTags = const [],
    this.growthPoints = const [],
    this.aiEmotion,
    required this.companionScene,
    required this.companionPose,
    required this.momentDate,
    required this.createdAt,
    this.clientEventId,
    this.note,
    this.contentType = 'text',
    this.voiceUrl,
    this.voiceDuration,
    this.voiceSize,
    this.speechStatus,
    this.speechText,
    this.visualPayload = const {},
    this.photos = const [],
  });

  final String id;
  final List<String> eventTags;
  final String emotionTag;
  final String? primaryTag;
  final List<String> secondaryTags;
  final List<String> growthPoints;
  final String? aiEmotion;
  final String? note;
  final String contentType;
  final String? voiceUrl;
  final int? voiceDuration;
  final int? voiceSize;
  final String? speechStatus;
  final String? speechText;
  final String? clientEventId;
  final String companionScene;
  final String companionPose;
  final DateTime momentDate;
  final DateTime createdAt;
  final Map<String, dynamic> visualPayload;
  final List<MomentPhotoModel> photos;

  bool get isVoice => contentType == 'voice';

  /// 优先使用 AI 标签字段，兼容旧 event_tags。
  List<String> get effectiveTagLabels {
    final primary = primaryTag?.trim();
    if (primary != null && primary.isNotEmpty) {
      return [
        primary,
        ...secondaryTags.where((tag) => tag.trim().isNotEmpty),
      ];
    }
    return eventTags;
  }

  String get actionType =>
      visualPayload['animation_type'] as String? ??
      visualPayload['action_type'] as String? ??
      'wave';

  CompanionSpec get companionSpec {
    final payload = Map<String, dynamic>.from(visualPayload);
    payload['event_tags'] = effectiveTagLabels;
    payload['note_hint'] = momentStoryNote(this);
    payload['emotion_tag'] = emotionTag;
    return CompanionSpec.fromPayload(
      payload,
      fallbackMood: emotionTag,
      inferSeed: Object.hashAll([
        ...effectiveTagLabels,
        note,
        visualPayload['prop'],
      ]),
    );
  }

  String? get sceneTitle => visualPayload['scene_title'] as String?;

  List<String> get waitingLines {
    final raw = visualPayload['waiting_lines'];
    if (raw is List) return raw.map((e) => '$e').toList();
    return const [];
  }

  List<String> waitingLinesFor(String? nickname) {
    return applyCompanionNicknameLines(waitingLines, nickname);
  }

  /// 日常对话式陪伴语（AI 分析时生成，详情页点击小人随机展示其一）。
  List<String> get storySummaryLines => storySummaryLinesFor(null);

  List<String> storySummaryLinesFor(String? nickname) {
    final raw = visualPayload['story_summary_lines'];
    if (raw is List) {
      final templates = raw
          .map((e) => '$e'.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (templates.isNotEmpty) {
        return applyCompanionNicknameLines(templates, nickname);
      }
    }
    return applyCompanionNicknameLines(_fallbackDialogueTemplates(), nickname);
  }

  List<String> _fallbackDialogueTemplates() {
    final tag = effectiveTagLabels.isNotEmpty
        ? effectiveTagLabels.where((t) => t != '自定义').first
        : '生活';
    final moodLabel = switch (emotionTag) {
      'happy' => '开心',
      'sad' => '有点难过',
      'angry' => '心里闷闷的',
      'thinking' => '若有所思',
      _ => '平静',
    };
    if (note != null && note!.trim().isNotEmpty) {
      final snippet = note!.trim();
      return [
        '$companionNicknamePlaceholder，今天辛苦啦，$snippet我都记得',
        '今天$tag对我们$companionNicknamePlaceholder怎么样呀？',
        '$companionNicknamePlaceholder，那一刻$moodLabel，我替你收好了',
      ];
    }
    return [
      '$companionNicknamePlaceholder，今天辛苦啦',
      '今天$tag对我们$companionNicknamePlaceholder怎么样呀？',
      '$companionNicknamePlaceholder，这件事值得被记住',
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
      primaryTag: json['primary_tag'] as String?,
      secondaryTags: (json['secondary_tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      growthPoints: (json['growth_points'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      aiEmotion: json['ai_emotion'] as String?,
      clientEventId: json['client_event_id'] as String?,
      note: json['note'] as String?,
      contentType: json['content_type'] as String? ?? 'text',
      voiceUrl: json['voice_url'] as String?,
      voiceDuration: json['voice_duration'] as int?,
      voiceSize: json['voice_size'] as int?,
      speechStatus: json['speech_status'] as String?,
      speechText: json['speech_text'] as String?,
      companionScene: json['companion_scene'] as String,
      companionPose: json['companion_pose'] as String? ?? 'breathing',
      momentDate: _parseDate(json['moment_date']),
      createdAt: _parseDateTime(json['created_at']),
      visualPayload: json['visual_payload'] as Map<String, dynamic>? ?? {},
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => MomentPhotoModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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
