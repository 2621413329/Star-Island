import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../models/mood_check_in_models.dart';
import '../models/growth_observation_models.dart';
import '../models/mood_report_models.dart';
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

  Future<String> studentRegister({
    required String username,
    required String nickname,
    required String password,
    required String className,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/auth/student-register',
        data: {
          'username': username,
          'nickname': nickname,
          'password': password,
          'class_name': className,
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
    required List<String> eventTags,
    required String emotionTag,
    required String clientEventId,
    String? note,
  }) {
    return unwrap(
      _dio.post(
        '/api/v1/profile/moments',
        data: {
          'event_tags': eventTags,
          'emotion_tag': emotionTag,
          'client_event_id': clientEventId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
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

  /// 最近 N 天故事（用于日期筛选条；需较新的后端）。
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

  Future<List<DailyMomentModel>> listTodayMoments() {
    return unwrap(
      _dio.get('/api/v1/profile/moments/today'),
      (data) => (data as List<dynamic>)
          .map((e) => DailyMomentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<DailyMomentModel> updateMoment({
    required String id,
    required List<String> eventTags,
    required String emotionTag,
    String? note,
  }) {
    return unwrap(
      _dio.patch(
        '/api/v1/profile/moments/$id',
        data: {
          'event_tags': eventTags,
          'emotion_tag': emotionTag,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      ),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
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

  Future<StudentGrowthObservation> getStudentGrowthObservation({int days = 7}) {
    return unwrap(
      _dio.get(
        '/api/v1/profile/growth-observation',
        queryParameters: {'days': days},
      ),
      (data) => StudentGrowthObservation.fromJson(data as Map<String, dynamic>),
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
}
