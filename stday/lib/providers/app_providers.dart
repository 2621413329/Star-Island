import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/mood_island_config.dart';
import '../core/models/user_companion.dart';
import '../core/notifications/story_reminder_service.dart';
import '../core/theme/mood_theme.dart';
import '../core/storage/user_app_preferences_sync.dart';
import '../core/constants/emotion_catalog.dart';
import '../core/utils/mood_stats.dart';
import '../data/models/profile_models.dart';
import '../data/models/story_island_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';
import 'growth_observation_provider.dart';
import 'growth_tag_provider.dart';
import 'mood_report_check_in_provider.dart';
import 'mood_status_provider.dart';

final userAppPreferencesSyncProvider = Provider<UserAppPreferencesSync>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn) {
    return UserAppPreferencesSync();
  }
  return UserAppPreferencesSync(
      patcher: ref.watch(userPreferencesRepositoryProvider));
});

final moodIslandRegistryProvider =
    AsyncNotifierProvider<MoodIslandRegistryNotifier, MoodIslandRegistry>(
  MoodIslandRegistryNotifier.new,
);

class MoodIslandRegistryNotifier extends AsyncNotifier<MoodIslandRegistry> {
  @override
  Future<MoodIslandRegistry> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return MoodIslandRegistry.defaults();
    try {
      final rows =
          await ref.read(islandConfigRepositoryProvider).listIslandStyles();
      final map = <String, MoodIslandConfig>{};
      for (final row in rows) {
        final moodId = row['mood_id'] as String;
        map[moodId] = MoodIslandConfig.fromJson(moodId, row);
      }
      if (map.isEmpty) return MoodIslandRegistry.defaults();
      return MoodIslandRegistry(map);
    } catch (_) {
      return MoodIslandRegistry.defaults();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfileModel?>(
        ProfileNotifier.new);

final todayMomentsProvider =
    AsyncNotifierProvider<TodayMomentsNotifier, List<DailyMomentModel>>(
  TodayMomentsNotifier.new,
);

final storyIslandGroupsProvider = AsyncNotifierProvider<
    StoryIslandGroupsNotifier, List<StoryIslandCategoryModel>>(
  StoryIslandGroupsNotifier.new,
);

const _fallbackStoryIslandCategories = [
  StoryIslandCategoryModel(
    id: 'work',
    label: '工作',
    icon: 'work',
    color: '#FF6658',
    sortOrder: 10,
  ),
  StoryIslandCategoryModel(
    id: 'study',
    label: '学业',
    icon: 'school',
    color: '#5DADEC',
    sortOrder: 20,
  ),
  StoryIslandCategoryModel(
    id: 'health',
    label: '健康',
    icon: 'eco',
    color: '#4DBA7A',
    sortOrder: 30,
  ),
  StoryIslandCategoryModel(
    id: 'social',
    label: '人际',
    icon: 'heart',
    color: '#F48FB1',
    sortOrder: 40,
  ),
  StoryIslandCategoryModel(
    id: 'life',
    label: '生活',
    icon: 'home',
    color: '#F4A261',
    sortOrder: 50,
  ),
  StoryIslandCategoryModel(
    id: 'finance',
    label: '财富',
    icon: 'shield',
    color: '#A1887F',
    sortOrder: 60,
  ),
];

List<StoryIslandCategoryModel> _storyIslandCategoriesWithFallback(
  List<StoryIslandCategoryModel> remote,
) {
  if (remote.isEmpty) return _fallbackStoryIslandCategories;
  final byId = {for (final group in remote) group.id: group};
  return [
    for (final fallback in _fallbackStoryIslandCategories)
      byId[fallback.id] ?? fallback,
    for (final group in remote)
      if (!_fallbackStoryIslandCategories.any((item) => item.id == group.id))
        group,
  ];
}

class StorySeedAnimationRequest {
  const StorySeedAnimationRequest({
    required this.momentId,
    required this.toIslandId,
    this.fromIslandId,
    this.toIslandName,
    this.fromIslandName,
  });

  final String momentId;
  final String toIslandId;
  final String? fromIslandId;
  final String? toIslandName;
  final String? fromIslandName;
}

final pendingStorySeedAnimationProvider =
    StateProvider<StorySeedAnimationRequest?>((_) => null);

final moodPaletteProvider = Provider<MoodPalette>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final todayMoments = ref.watch(todayMomentsProvider).valueOrNull ?? const [];
  String? atmosphereMood;
  if (todayMoments.isNotEmpty) {
    final counts = moodCountsForMoments(todayMoments);
    final dominant = dominantMoodId(counts);
    if (dominant != null) {
      atmosphereMood = emotionById(dominant).legacyMoodId;
    }
  }
  atmosphereMood ??= profile?.todayMood != null
      ? emotionById(profile!.todayMood).legacyMoodId
      : null;
  return paletteForMood(atmosphereMood);
});

/// 当前登录用户的小人基础样貌，全应用统一引用此对象。
final userCompanionProvider = Provider<UserCompanion>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  return UserCompanion.fromProfile(profile);
});

class ProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  Future<UserProfileModel?> _loadProfile() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return null;
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    await ref.read(userAppPreferencesSyncProvider).hydrateFromServer(
          profile.appPreferences,
          userId: profile.userId,
        );
    unawaited(_syncStoryReminders(profile.appPreferences));
    ref.invalidate(growthTagCatalogProvider);
    return profile;
  }

  Future<void> _syncStoryReminders(Map<String, dynamic> prefs) async {
    try {
      final service = ref.read(storyReminderServiceProvider);
      await service.ensureSchedulePermissions();
      await service.scheduleFromPreferences(prefs);
    } catch (e, st) {
      debugPrint('StoryReminder sync failed: $e\n$st');
    }
  }

  @override
  Future<UserProfileModel?> build() async {
    return _loadProfile();
  }

  Future<void> refresh() async {
    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(_loadProfile);
  }

  Future<UserProfileModel> updateNickname(String nickname) async {
    final p =
        await ref.read(profileRepositoryProvider).updateNickname(nickname);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateCompanionRole(String companionRoleId) async {
    final p = await ref
        .read(profileRepositoryProvider)
        .updateCompanionRole(companionRoleId);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateGender(String gender) async {
    final p = await ref.read(profileRepositoryProvider).updateGender(gender);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateCompanion(String style) async {
    final p = await ref.read(profileRepositoryProvider).updateCompanion(style);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateMood(String mood) async {
    final p = await ref.read(profileRepositoryProvider).updateMood(mood);
    state = AsyncData(p);
    return p;
  }

  Future<void> completeOnboarding() async {
    final p = await ref.read(profileRepositoryProvider).completeOnboarding();
    state = AsyncData(p);
  }
}

class TodayMomentsNotifier extends AsyncNotifier<List<DailyMomentModel>> {
  @override
  Future<List<DailyMomentModel>> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return [];
    return ref.read(momentRepositoryProvider).listTodayMoments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(momentRepositoryProvider).listTodayMoments());
  }

  Future<DailyMomentModel> add({
    required String note,
    required String clientEventId,
  }) async {
    final moment = await ref.read(momentRepositoryProvider).createMoment(
          note: note,
          clientEventId: clientEventId,
        );
    await refresh();
    await ref.read(profileProvider.notifier).refresh();
    final synced = state.valueOrNull ?? [];
    return synced.firstWhere((m) => m.id == moment.id, orElse: () => moment);
  }

  Future<DailyMomentModel> updateMoment({
    required String id,
    required String note,
  }) async {
    final moment = await ref.read(momentRepositoryProvider).updateMoment(
          id: id,
          note: note,
        );
    await refresh();
    await ref.read(profileProvider.notifier).refresh();
    final synced = state.valueOrNull ?? [];
    return synced.firstWhere((m) => m.id == moment.id, orElse: () => moment);
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? [];

    await ref.read(momentRepositoryProvider).deleteMoment(id);

    // 后端确认删除后再更新 UI，避免“假删除”掩盖数据库删除失败。
    state = AsyncData(current.where((m) => m.id != id).toList());
    await refresh();
    await ref.read(profileProvider.notifier).refresh();
    _invalidateGrowthTrajectoryCaches();
    _syncDailyMoodReportAfterMomentChange();
  }

  void _invalidateGrowthTrajectoryCaches() {
    ref.invalidate(moodStatusViewProvider);
    ref.invalidate(moodReportCheckInProvider);
    ref.invalidate(moodPeriodSummaryProvider);
    ref.invalidate(weeklySummaryProvider);
  }

  void _syncDailyMoodReportAfterMomentChange() {
    final moments = state.valueOrNull ?? [];
    if (moments.isEmpty) return;
    unawaited(
      ref.read(moodRepositoryProvider).uploadDailyMoodReport().then((_) {
        ref.invalidate(moodReportCheckInProvider);
        ref.invalidate(moodStatusViewProvider);
        ref.invalidate(moodPeriodSummaryProvider);
      }).catchError((_) {}),
    );
  }
}

class StoryIslandGroupsNotifier
    extends AsyncNotifier<List<StoryIslandCategoryModel>> {
  @override
  Future<List<StoryIslandCategoryModel>> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return _fallbackStoryIslandCategories;
    try {
      final groups =
          await ref.read(storyIslandRepositoryProvider).listStoryIslands();
      return _storyIslandCategoriesWithFallback(groups);
    } catch (_) {
      return _fallbackStoryIslandCategories;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<StoryIslandModel> createIsland({
    required String categoryId,
    required String name,
    int targetCompletionDays = 90,
    DateTime? completionTargetDate,
    String sizeKind = 'small',
  }) async {
    final island =
        await ref.read(storyIslandRepositoryProvider).createStoryIsland(
              categoryId: categoryId,
              name: name,
              targetCompletionDays: targetCompletionDays,
              completionTargetDate: completionTargetDate,
              sizeKind: sizeKind,
            );
    await refresh();
    return island;
  }

  Future<StoryIslandModel> updateIsland({
    required String id,
    String? name,
    int? targetCompletionDays,
    DateTime? completionTargetDate,
    String? sizeKind,
    Map<String, dynamic>? backgroundConfig,
    String? coverImageKey,
    bool? isArchived,
  }) async {
    final island =
        await ref.read(storyIslandRepositoryProvider).updateStoryIsland(
              id: id,
              name: name,
              targetCompletionDays: targetCompletionDays,
              completionTargetDate: completionTargetDate,
              sizeKind: sizeKind,
              backgroundConfig: backgroundConfig,
              coverImageKey: coverImageKey,
              isArchived: isArchived,
            );
    await refresh();
    return island;
  }

  Future<void> createTask({
    required String islandId,
    required String title,
    required bool isDaily,
  }) async {
    await ref.read(storyIslandRepositoryProvider).createTask(
          islandId: islandId,
          title: title,
          isDaily: isDaily,
        );
    await refresh();
  }

  Future<void> updateTask({
    required String islandId,
    required String taskId,
    String? title,
    bool? isDaily,
  }) async {
    await ref.read(storyIslandRepositoryProvider).updateTask(
          islandId: islandId,
          taskId: taskId,
          title: title,
          isDaily: isDaily,
        );
    await refresh();
  }

  Future<void> deleteTask({
    required String islandId,
    required String taskId,
  }) async {
    await ref.read(storyIslandRepositoryProvider).deleteTask(
          islandId: islandId,
          taskId: taskId,
        );
    await refresh();
  }

  Future<void> completeTask({
    required String islandId,
    required String taskId,
  }) async {
    await ref.read(storyIslandRepositoryProvider).completeTask(
          islandId: islandId,
          taskId: taskId,
        );
    await refresh();
  }

  Future<void> uncompleteTask({
    required String islandId,
    required String taskId,
  }) async {
    await ref.read(storyIslandRepositoryProvider).uncompleteTask(
          islandId: islandId,
          taskId: taskId,
        );
    await refresh();
  }
}
