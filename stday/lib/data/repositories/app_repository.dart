import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../models/profile_models.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(dioProvider));
});

class AppRepository {
  AppRepository(this._dio);
  final Dio _dio;

  Future<AuthEntryResult> authEntry(String username, String password) {
    return unwrap(
      _dio.post('/api/v1/auth/entry', data: {'username': username, 'password': password}),
      (data) => AuthEntryResult(
        accessToken: (data['token'] as Map)['access_token'] as String,
        isNewUser: data['is_new_user'] as bool? ?? false,
      ),
    );
  }

  Future<UserProfileModel> getProfile() {
    return unwrap(
      _dio.get('/api/v1/profile'),
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

  Future<DailyMomentModel> createMoment({
    required List<String> eventTags,
    required String emotionTag,
    String? note,
  }) {
    return unwrap(
      _dio.post('/api/v1/profile/moments', data: {
        'event_tags': eventTags,
        'emotion_tag': emotionTag,
        if (note != null && note.isNotEmpty) 'note': note,
      }),
      (data) => DailyMomentModel.fromJson(data as Map<String, dynamic>),
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

  Future<List<Map<String, dynamic>>> listIslandStyles() {
    return unwrap(
      _dio.get('/api/v1/profile/island-styles'),
      (data) => (data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    );
  }
}
