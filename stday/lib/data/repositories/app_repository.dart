import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/sync/client_event_id.dart';
import '../../core/storage/user_app_preferences_sync.dart';
import '../../core/voice/voice_file_io_export.dart';
import '../models/building_unlock_models.dart';
import '../models/growth_tag_models.dart';
import '../models/mood_check_in_models.dart';
import '../models/growth_observation_models.dart';
import '../models/mood_report_models.dart';
import '../models/paginated_moments_model.dart';
import '../../core/growth/growth_system.dart';
import '../models/profile_models.dart';
import '../models/story_island_models.dart';

part 'app_repository_facades.dart';

class StdayApiDatasource implements UserAppPreferencesPatcher {
  StdayApiDatasource(this._dio);
  final Dio _dio;

  Future<AuthEntryResult> authEntry(String username, String password) {
    return unwrap(
      _dio.post('/api/v1/auth/entry',
          data: {'username': username, 'password': password}),
      (data) => AuthEntryResult(
        accessToken: (data['token'] as Map)['access_token'] as String,
        isNewUser: data['is_new_user'] as bool? ?? false,
      ),
    );
  }

  Future<String> login({
    required String username,
    required String password,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      ),
      (data) => (data as Map)['access_token'] as String,
    );
  }

  Future<String> register({
    required String username,
    required String nickname,
    required String password,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/auth/register',
        data: {
          'username': username,
          'nickname': nickname,
          'password': password,
        },
      ),
      (data) => (data as Map)['access_token'] as String,
    );
  }

  Future<UserProfileModel> getProfile() {
    return unwrap(
      _dio.get('/api/v1/profile'),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> updateNickname(String nickname) {
    return unwrap(
      _dio.patch('/api/v1/profile/nickname', data: {'nickname': nickname}),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> updateCompanionRole(String companionRoleId) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/companion-role',
        data: {'companion_role_id': companionRoleId},
      ),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> updateGender(String gender) {
    return unwrap(
      _dio.patch('/api/v1/profile/gender', data: {'gender': gender}),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> updateCompanion(String style) {
    return unwrap(
      _dio.patch('/api/v1/profile/companion', data: {'companion_style': style}),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> updateMood(String mood) {
    return unwrap(
      _dio.patch('/api/v1/profile/mood', data: {'today_mood': mood}),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<UserProfileModel> completeOnboarding() {
    return unwrap(
      _dio.post('/api/v1/profile/onboarding/complete'),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<UserProfileModel> patchAppPreferences(Map<String, dynamic> payload) {
    return unwrap(
      _dio.patch('/api/v1/profile/app-preferences', data: payload),
      (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMomentModel> createMoment({
    required String note,
    required String clientEventId,
    DateTime? momentDate,
  }) {
    final payload = <String, dynamic>{
      'note': note,
      'client_event_id': clientEventId,
    };
    if (momentDate != null) {
      final d = momentDate;
      payload['moment_date'] =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return unwrap(
      _dio.post(
        '/api/v1/profile/moments',
        data: payload,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<String> transcribeSpeechNote({
    required String filePath,
    required int voiceDuration,
  }) async {
    const endpoints = [
      '/api/v1/profile/speech/transcribe',
      '/api/v1/profile/moments/voice/transcribe',
    ];
    ApiException? lastError;
    for (final path in endpoints) {
      try {
        final attemptForm = await _buildVoiceUploadForm(
          filePath: filePath,
          voiceDuration: voiceDuration,
        );
        return await _requestSpeechTranscription(path, attemptForm);
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404) continue;
        rethrow;
      }
    }
    try {
      return await _transcribeViaTemporaryVoiceMoment(
        filePath: filePath,
        voiceDuration: voiceDuration,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (lastError != null) throw lastError;
      rethrow;
    }
  }

  Future<FormData> _buildVoiceUploadForm({
    required String filePath,
    required int voiceDuration,
    String? clientEventId,
    DateTime? momentDate,
  }) async {
    final bytes = await readVoiceFileBytes(filePath);
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'voice.m4a',
        contentType: MediaType('audio', 'mp4'),
      ),
      'voice_duration': voiceDuration,
      if (clientEventId != null) 'client_event_id': clientEventId,
      if (momentDate != null)
        'moment_date':
            '${momentDate.year}-${momentDate.month.toString().padLeft(2, '0')}-${momentDate.day.toString().padLeft(2, '0')}',
    });
  }

  Future<String> _requestSpeechTranscription(String path, FormData form) {
    return unwrap(
      _dio.post(
        path,
        data: form,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      ),
      (data) => (data as Map<String, dynamic>)['text'] as String,
    );
  }

  Future<String> _transcribeViaTemporaryVoiceMoment({
    required String filePath,
    required int voiceDuration,
  }) async {
    final moment = await createVoiceMoment(
      filePath: filePath,
      voiceDuration: voiceDuration,
      clientEventId: ClientEventId.next('speech-note-temp'),
    );
    try {
      return await _pollMomentSpeechText(moment.id);
    } finally {
      try {
        await deleteMoment(moment.id);
      } catch (_) {}
    }
  }

  Future<String> _pollMomentSpeechText(String momentId) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final moments = await listTodayMoments();
      DailyMomentModel? match;
      for (final moment in moments) {
        if (moment.id == momentId) {
          match = moment;
          break;
        }
      }
      if (match != null) {
        final text = match.speechText?.trim();
        if (text != null && text.isNotEmpty) return text;
        final status = match.speechStatus;
        if (status == 'failed') {
          throw ApiException('未识别到语音，请重试');
        }
        if (status == 'success' && (text == null || text.isEmpty)) {
          throw ApiException('未识别到语音，请重试');
        }
      }
      if (attempt < 29) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw ApiException('语音转写超时，请重试');
  }

  Future<DailyMomentModel> createVoiceMoment({
    required String filePath,
    required int voiceDuration,
    required String clientEventId,
    DateTime? momentDate,
  }) async {
    final form = await _buildVoiceUploadForm(
      filePath: filePath,
      voiceDuration: voiceDuration,
      clientEventId: clientEventId,
      momentDate: momentDate,
    );
    return unwrap(
      _dio.post(
        '/api/v1/profile/moments/voice',
        data: form,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMomentModel> updateMomentTags({
    required String id,
    required String primaryTag,
    required List<String> secondaryTags,
    String? aiEmotion,
  }) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/moments/$id/tags',
        data: {
          'primary_tag': primaryTag,
          'secondary_tags': secondaryTags,
          if (aiEmotion != null && aiEmotion.isNotEmpty)
            'ai_emotion': aiEmotion,
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMomentModel> replaceVoiceMoment({
    required String id,
    required String filePath,
    required int voiceDuration,
  }) async {
    final bytes = await readVoiceFileBytes(filePath);
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'voice.m4a',
        contentType: MediaType('audio', 'mp4'),
      ),
      'voice_duration': voiceDuration,
    });
    return unwrap(
      _dio.patch(
        '/api/v1/profile/moments/$id/voice',
        data: form,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMomentModel> updateMoment({
    required String id,
    required String note,
    String? primaryTag,
    List<String>? secondaryTags,
    String? emotionTag,
    String? aiEmotion,
  }) {
    final data = <String, dynamic>{'note': note};
    if (primaryTag != null) {
      data['primary_tag'] = primaryTag;
      data['secondary_tags'] = secondaryTags ?? [];
      if (emotionTag != null && emotionTag.isNotEmpty) {
        data['emotion_tag'] = emotionTag;
      }
      if (aiEmotion != null && aiEmotion.isNotEmpty) {
        data['ai_emotion'] = aiEmotion;
      }
    }
    return unwrap(
      _dio.patch(
        '/api/v1/profile/moments/$id',
        data: data,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<StoryIslandCategoryModel>> listStoryIslands() {
    return unwrap(
      _dio.get('/api/v1/profile/story-islands'),
      (data) => (data as List<dynamic>)
          .map((e) =>
              StoryIslandCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<StoryIslandModel> createStoryIsland({
    required String categoryId,
    required String name,
    int targetCompletionDays = 90,
    DateTime? completionTargetDate,
    String sizeKind = 'small',
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/story-islands',
        data: {
          'category_id': categoryId,
          'name': name,
          'target_completion_days': targetCompletionDays,
          'size_kind': sizeKind,
          if (completionTargetDate != null)
            'completion_target_date': _dateOnly(completionTargetDate),
        },
      ),
      (data) => StoryIslandModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandModel> updateStoryIsland({
    required String id,
    String? name,
    int? targetCompletionDays,
    DateTime? completionTargetDate,
    String? sizeKind,
    Map<String, dynamic>? backgroundConfig,
    String? coverImageKey,
    bool? isArchived,
  }) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/story-islands/$id',
        data: {
          if (name != null) 'name': name,
          if (targetCompletionDays != null)
            'target_completion_days': targetCompletionDays,
          if (sizeKind != null) 'size_kind': sizeKind,
          if (completionTargetDate != null)
            'completion_target_date': _dateOnly(completionTargetDate),
          if (backgroundConfig != null) 'background_config': backgroundConfig,
          if (coverImageKey != null) 'cover_image_key': coverImageKey,
          if (isArchived != null) 'is_archived': isArchived,
        },
      ),
      (data) => StoryIslandModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandTaskModel> createStoryIslandTask({
    required String islandId,
    required String title,
    required bool isDaily,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/story-islands/$islandId/tasks',
        data: {
          'title': title,
          'is_daily': isDaily,
        },
      ),
      (data) => StoryIslandTaskModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandTaskModel> updateStoryIslandTask({
    required String islandId,
    required String taskId,
    String? title,
    bool? isDaily,
  }) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/story-islands/$islandId/tasks/$taskId',
        data: {
          if (title != null) 'title': title,
          if (isDaily != null) 'is_daily': isDaily,
        },
      ),
      (data) => StoryIslandTaskModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandTaskModel> deleteStoryIslandTask({
    required String islandId,
    required String taskId,
  }) {
    return unwrap(
      _dio.delete('/api/v1/profile/story-islands/$islandId/tasks/$taskId'),
      (data) => StoryIslandTaskModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandModel> completeStoryIslandTask({
    required String islandId,
    required String taskId,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/story-islands/$islandId/tasks/$taskId/complete',
      ),
      (data) => StoryIslandModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<StoryIslandModel> uncompleteStoryIslandTask({
    required String islandId,
    required String taskId,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/story-islands/$islandId/tasks/$taskId/uncomplete',
      ),
      (data) => StoryIslandModel.fromJson(data as Map<String, dynamic>),
    );
  }

  String _dateOnly(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<DailyMomentModel> updateMomentStoryIsland({
    required String momentId,
    required String storyIslandId,
  }) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/moments/$momentId/story-island',
        data: {'story_island_id': storyIslandId},
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<GrowthTagCategoryModel>> listGrowthTags() {
    return unwrap(
      _dio.get('/api/v1/growth-tags'),
      (data) => (data as List<dynamic>)
          .map(
              (e) => GrowthTagCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<DailyMomentModel>> listMomentsForDate(DateTime day) {
    final iso =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return unwrap(
      _dio.get('/api/v1/profile/moments', queryParameters: {'date': iso}),
      (data) => (data as List<dynamic>)
          .map((e) => DailyMomentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 最近 N 天日常（用于日期筛选条；需较新的后端）。
  Future<List<DailyMomentModel>> listRecentMoments({int days = 90}) {
    return unwrap(
      _dio.get('/api/v1/profile/moments', queryParameters: {'days': days}),
      (data) => (data as List<dynamic>)
          .map((e) => DailyMomentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<String>> listMomentDates({int days = 90}) {
    return unwrap(
      _dio.get('/api/v1/profile/moments/dates',
          queryParameters: {'days': days}),
      (data) => (data as List<dynamic>).map((e) => '$e').toList(),
    );
  }

  Future<EmotionFragmentSummary> getEmotionFragments() {
    return unwrap(
      _dio.get('/api/v1/profile/emotion-fragments'),
      (data) => EmotionFragmentSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<GrowthSummary> getGrowthSummary({int days = 365}) {
    return unwrap(
      _dio.get('/api/v1/profile/growth-summary',
          queryParameters: {'days': days}),
      (data) => GrowthSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<BuildingUnlockModel>> listBuildingUnlocks() {
    return unwrap(
      _dio.get('/api/v1/profile/building-unlocks'),
      (data) => (data as List<dynamic>)
          .map((e) => BuildingUnlockModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<DailyMomentModel>> listTodayMoments() {
    return unwrap(
      _dio.get('/api/v1/profile/moments/today'),
      (data) => (data as List<dynamic>)
          .map((e) => DailyMomentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> deleteMoment(String id) async {
    await unwrap(
      _dio.delete(
        '/api/v1/profile/moments/$id',
        options:
            Options(validateStatus: (status) => status != null && status < 500),
      ),
      (_) {},
    );
  }

  Future<DailyMomentModel> uploadMomentPhoto({
    required String momentId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final name = file.name.trim().isNotEmpty ? file.name : 'photo.jpg';
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
    });
    return unwrap(
      _dio.post(
        '/api/v1/profile/moments/$momentId/photos',
        data: form,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMomentModel> deleteMomentPhoto({
    required String momentId,
    required String photoId,
  }) {
    return unwrap(
      _dio.delete('/api/v1/profile/moments/$momentId/photos/$photoId'),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<MoodReportCheckIn> getMoodReportCheckIn({int days = 365}) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/mood-report/check-in',
        queryParameters: {'days': days},
      ),
      (data) => MoodReportCheckIn.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<DailyMoodReportModel> uploadDailyMoodReport({String? categoryFilter}) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/mood-report/upload',
        data: {
          if (categoryFilter != null) 'category_filter': categoryFilter,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      ),
      (data) => DailyMoodReportModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<DailyMoodReportModel>> listMoodReports({required String period}) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/mood-reports',
        queryParameters: {'period': period},
      ),
      (data) => (data as List<dynamic>)
          .map(
            (e) => DailyMoodReportModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<MoodPeriodSummaryModel> fetchMoodPeriodSummary({
    required String period,
    String? categoryFilter,
  }) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/mood-period-summary',
        queryParameters: {
          'period': period,
          if (categoryFilter != null) 'category_filter': categoryFilter,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      ),
      (data) => MoodPeriodSummaryModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// 成长轨迹「本月 / 本年度」：服务端标签筛选 + 分页。
  Future<PaginatedMomentsModel> fetchMoodPeriodMoments({
    required String period,
    String? categoryFilter,
    int page = 1,
    int pageSize = 10,
  }) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/moments/mood-period',
        queryParameters: {
          'period': period,
          if (categoryFilter != null) 'category_filter': categoryFilter,
          'page': page,
          'page_size': pageSize,
        },
      ),
      (data) => PaginatedMomentsModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<WeeklySummary> getWeeklySummary({int days = 7}) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/growth-observation',
        queryParameters: {'days': days},
      ),
      (data) => WeeklySummary.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<Map<String, dynamic>>> listIslandStyles() {
    return unwrap(
      _dio.get('/api/v1/profile/island-styles'),
      (data) => (data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Future<Map<String, dynamic>> fetchI18nConfig() {
    return unwrap(
      _dio.get('/api/v1/i18n/config'),
      (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  Future<Map<String, String>> fetchI18nBundle(String locale) {
    return unwrap(
      _dio.get(
        '/api/v1/i18n/bundle',
        queryParameters: {'locale': locale},
      ),
      (data) {
        final map = Map<String, dynamic>.from(data as Map);
        return map.map((key, value) => MapEntry(key, value.toString()));
      },
    );
  }
}
