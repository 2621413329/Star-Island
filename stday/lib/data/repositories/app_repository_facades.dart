part of 'app_repository.dart';

final _stdayApiDatasourceProvider = Provider<StdayApiDatasource>((ref) {
  return StdayApiDatasource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(_stdayApiDatasourceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(_stdayApiDatasourceProvider));
});

final momentRepositoryProvider = Provider<MomentRepository>((ref) {
  return MomentRepository(ref.watch(_stdayApiDatasourceProvider));
});

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepository(ref.watch(_stdayApiDatasourceProvider));
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepository(ref.watch(_stdayApiDatasourceProvider));
});

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  return GrowthRepository(ref.watch(_stdayApiDatasourceProvider));
});

final islandConfigRepositoryProvider = Provider<IslandConfigRepository>((ref) {
  return IslandConfigRepository(ref.watch(_stdayApiDatasourceProvider));
});

final storyIslandRepositoryProvider = Provider<StoryIslandRepository>((ref) {
  return StoryIslandRepository(ref.watch(_stdayApiDatasourceProvider));
});

final appLocalizationRepositoryProvider =
    Provider<AppLocalizationRepository>((ref) {
  return AppLocalizationRepository(ref.watch(_stdayApiDatasourceProvider));
});

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository(ref.watch(_stdayApiDatasourceProvider));
});

class AuthRepository {
  const AuthRepository(this._api);
  final StdayApiDatasource _api;

  Future<AuthEntryResult> authEntry(String username, String password) =>
      _api.authEntry(username, password);

  Future<String> login({
    required String username,
    required String password,
  }) =>
      _api.login(username: username, password: password);

  Future<String> register({
    required String username,
    required String nickname,
    required String password,
  }) =>
      _api.register(username: username, nickname: nickname, password: password);
}

class ProfileRepository {
  const ProfileRepository(this._api);
  final StdayApiDatasource _api;

  Future<UserProfileModel> getProfile() => _api.getProfile();
  Future<UserProfileModel> updateNickname(String nickname) =>
      _api.updateNickname(nickname);
  Future<UserProfileModel> updateCompanionRole(String companionRoleId) =>
      _api.updateCompanionRole(companionRoleId);
  Future<UserProfileModel> updateGender(String gender) =>
      _api.updateGender(gender);
  Future<UserProfileModel> updateCompanion(String style) =>
      _api.updateCompanion(style);
  Future<UserProfileModel> updateMood(String mood) => _api.updateMood(mood);
  Future<UserProfileModel> completeOnboarding() => _api.completeOnboarding();
}

class MomentRepository {
  const MomentRepository(this._api);
  final StdayApiDatasource _api;

  Future<DailyMomentModel> createMoment({
    required String note,
    required String clientEventId,
    DateTime? momentDate,
  }) =>
      _api.createMoment(
        note: note,
        clientEventId: clientEventId,
        momentDate: momentDate,
      );

  Future<DailyMomentModel> createVoiceMoment({
    required String filePath,
    required int voiceDuration,
    required String clientEventId,
    DateTime? momentDate,
  }) =>
      _api.createVoiceMoment(
        filePath: filePath,
        voiceDuration: voiceDuration,
        clientEventId: clientEventId,
        momentDate: momentDate,
      );

  Future<DailyMomentModel> updateMomentTags({
    required String id,
    required String primaryTag,
    required List<String> secondaryTags,
    String? aiEmotion,
  }) =>
      _api.updateMomentTags(
        id: id,
        primaryTag: primaryTag,
        secondaryTags: secondaryTags,
        aiEmotion: aiEmotion,
      );

  Future<DailyMomentModel> replaceVoiceMoment({
    required String id,
    required String filePath,
    required int voiceDuration,
  }) =>
      _api.replaceVoiceMoment(
        id: id,
        filePath: filePath,
        voiceDuration: voiceDuration,
      );

  Future<DailyMomentModel> updateMoment({
    required String id,
    required String note,
    String? primaryTag,
    List<String>? secondaryTags,
    String? emotionTag,
    String? aiEmotion,
  }) =>
      _api.updateMoment(
        id: id,
        note: note,
        primaryTag: primaryTag,
        secondaryTags: secondaryTags,
        emotionTag: emotionTag,
        aiEmotion: aiEmotion,
      );

  Future<List<DailyMomentModel>> listMomentsForDate(DateTime day) =>
      _api.listMomentsForDate(day);
  Future<List<DailyMomentModel>> listRecentMoments({int days = 90}) =>
      _api.listRecentMoments(days: days);
  Future<List<String>> listMomentDates({int days = 90}) =>
      _api.listMomentDates(days: days);
  Future<List<DailyMomentModel>> listTodayMoments() => _api.listTodayMoments();
  Future<void> deleteMoment(String id) => _api.deleteMoment(id);

  Future<DailyMomentModel> updateMomentStoryIsland({
    required String momentId,
    required String storyIslandId,
  }) =>
      _api.updateMomentStoryIsland(
        momentId: momentId,
        storyIslandId: storyIslandId,
      );

  Future<DailyMomentModel> uploadMomentPhoto({
    required String momentId,
    required XFile file,
  }) =>
      _api.uploadMomentPhoto(momentId: momentId, file: file);

  Future<DailyMomentModel> deleteMomentPhoto({
    required String momentId,
    required String photoId,
  }) =>
      _api.deleteMomentPhoto(momentId: momentId, photoId: photoId);
}

class StoryIslandRepository {
  const StoryIslandRepository(this._api);
  final StdayApiDatasource _api;

  Future<List<StoryIslandCategoryModel>> listStoryIslands() =>
      _api.listStoryIslands();

  Future<StoryIslandModel> createStoryIsland({
    required String categoryId,
    required String name,
    int targetCompletionDays = 90,
    DateTime? completionTargetDate,
    String sizeKind = 'small',
  }) =>
      _api.createStoryIsland(
        categoryId: categoryId,
        name: name,
        targetCompletionDays: targetCompletionDays,
        completionTargetDate: completionTargetDate,
        sizeKind: sizeKind,
      );

  Future<StoryIslandModel> updateStoryIsland({
    required String id,
    String? name,
    int? targetCompletionDays,
    DateTime? completionTargetDate,
    String? sizeKind,
    Map<String, dynamic>? backgroundConfig,
    String? coverImageKey,
    bool? isArchived,
  }) =>
      _api.updateStoryIsland(
        id: id,
        name: name,
        targetCompletionDays: targetCompletionDays,
        completionTargetDate: completionTargetDate,
        sizeKind: sizeKind,
        backgroundConfig: backgroundConfig,
        coverImageKey: coverImageKey,
        isArchived: isArchived,
      );

  Future<StoryIslandTaskModel> createTask({
    required String islandId,
    required String title,
    required bool isDaily,
  }) =>
      _api.createStoryIslandTask(
        islandId: islandId,
        title: title,
        isDaily: isDaily,
      );

  Future<StoryIslandTaskModel> updateTask({
    required String islandId,
    required String taskId,
    String? title,
    bool? isDaily,
  }) =>
      _api.updateStoryIslandTask(
        islandId: islandId,
        taskId: taskId,
        title: title,
        isDaily: isDaily,
      );

  Future<StoryIslandTaskModel> deleteTask({
    required String islandId,
    required String taskId,
  }) =>
      _api.deleteStoryIslandTask(islandId: islandId, taskId: taskId);

  Future<StoryIslandModel> completeTask({
    required String islandId,
    required String taskId,
  }) =>
      _api.completeStoryIslandTask(islandId: islandId, taskId: taskId);
}

class VoiceRepository {
  const VoiceRepository(this._api);
  final StdayApiDatasource _api;

  Future<String> transcribeSpeechNote({
    required String filePath,
    required int voiceDuration,
  }) =>
      _api.transcribeSpeechNote(
        filePath: filePath,
        voiceDuration: voiceDuration,
      );
}

class MoodRepository {
  const MoodRepository(this._api);
  final StdayApiDatasource _api;

  Future<MoodReportCheckIn> getMoodReportCheckIn({int days = 365}) =>
      _api.getMoodReportCheckIn(days: days);
  Future<DailyMoodReportModel> uploadDailyMoodReport(
          {String? categoryFilter}) =>
      _api.uploadDailyMoodReport(categoryFilter: categoryFilter);
  Future<List<DailyMoodReportModel>> listMoodReports({
    required String period,
  }) =>
      _api.listMoodReports(period: period);
  Future<MoodPeriodSummaryModel> fetchMoodPeriodSummary({
    required String period,
    String? categoryFilter,
  }) =>
      _api.fetchMoodPeriodSummary(
        period: period,
        categoryFilter: categoryFilter,
      );
  Future<PaginatedMomentsModel> fetchMoodPeriodMoments({
    required String period,
    String? categoryFilter,
    int page = 1,
    int pageSize = 10,
  }) =>
      _api.fetchMoodPeriodMoments(
        period: period,
        categoryFilter: categoryFilter,
        page: page,
        pageSize: pageSize,
      );
}

class GrowthRepository {
  const GrowthRepository(this._api);
  final StdayApiDatasource _api;

  Future<List<GrowthTagCategoryModel>> listGrowthTags() =>
      _api.listGrowthTags();
  Future<EmotionFragmentSummary> getEmotionFragments() =>
      _api.getEmotionFragments();
  Future<GrowthSummary> getGrowthSummary({int days = 365}) =>
      _api.getGrowthSummary(days: days);
  Future<List<BuildingUnlockModel>> listBuildingUnlocks() =>
      _api.listBuildingUnlocks();
  Future<WeeklySummary> getWeeklySummary({int days = 7}) =>
      _api.getWeeklySummary(days: days);
}

class IslandConfigRepository {
  const IslandConfigRepository(this._api);
  final StdayApiDatasource _api;

  Future<List<Map<String, dynamic>>> listIslandStyles() =>
      _api.listIslandStyles();
}

class AppLocalizationRepository {
  const AppLocalizationRepository(this._api);
  final StdayApiDatasource _api;

  Future<Map<String, dynamic>> fetchI18nConfig() => _api.fetchI18nConfig();
  Future<Map<String, String>> fetchI18nBundle(String locale) =>
      _api.fetchI18nBundle(locale);
}

class UserPreferencesRepository implements UserAppPreferencesPatcher {
  const UserPreferencesRepository(this._api);
  final StdayApiDatasource _api;

  @override
  Future<UserProfileModel> patchAppPreferences(Map<String, dynamic> payload) =>
      _api.patchAppPreferences(payload);
}
