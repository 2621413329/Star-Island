import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/voice/voice_file_io_export.dart';
import '../models/building_unlock_models.dart';
import '../models/growth_tag_models.dart';
import '../models/mood_check_in_models.dart';
import '../models/growth_observation_models.dart';
import '../models/mood_report_models.dart';
import '../models/paginated_moments_model.dart';
import '../../core/growth/growth_system.dart';
import '../models/profile_models.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(dioProvider));
});

class AppRepository {
  AppRepository(this._dio);
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
      _dio.post(
        '/api/v1/profile/speech/transcribe',
        data: form,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      ),
      (data) => (data as Map<String, dynamic>)['text'] as String,
    );
  }

  Future<DailyMomentModel> createVoiceMoment({
    required String filePath,
    required int voiceDuration,
    required String clientEventId,
  }) async {
    final bytes = await readVoiceFileBytes(filePath);
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'voice.m4a',
        contentType: MediaType('audio', 'mp4'),
      ),
      'voice_duration': voiceDuration,
      'client_event_id': clientEventId,
    });
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
          if (aiEmotion != null && aiEmotion.isNotEmpty) 'ai_emotion': aiEmotion,
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

  Future<List<GrowthTagCategoryModel>> listGrowthTags() {
    return unwrap(
      _dio.get('/api/v1/growth-tags'),
      (data) => (data as List<dynamic>)
          .map((e) => GrowthTagCategoryModel.fromJson(e as Map<String, dynamic>))
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
      (data) =>
          MoodPeriodSummaryModel.fromJson(data as Map<String, dynamic>),
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
