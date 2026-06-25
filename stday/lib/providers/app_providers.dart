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
  return UserAppPreferencesSync(repository: ref.watch(appRepositoryProvider));
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
      final rows = await ref.read(appRepositoryProvider).listIslandStyles();
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
    final profile = await ref.read(appRepositoryProvider).getProfile();
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
    final p = await ref.read(appRepositoryProvider).updateNickname(nickname);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateCompanionRole(String companionRoleId) async {
    final p =
        await ref.read(appRepositoryProvider).updateCompanionRole(companionRoleId);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateGender(String gender) async {
    final p = await ref.read(appRepositoryProvider).updateGender(gender);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateCompanion(String style) async {
    final p = await ref.read(appRepositoryProvider).updateCompanion(style);
    state = AsyncData(p);
    return p;
  }

  Future<UserProfileModel> updateMood(String mood) async {
    final p = await ref.read(appRepositoryProvider).updateMood(mood);
    state = AsyncData(p);
    return p;
  }

  Future<void> completeOnboarding() async {
    final p = await ref.read(appRepositoryProvider).completeOnboarding();
    state = AsyncData(p);
  }
}

class TodayMomentsNotifier extends AsyncNotifier<List<DailyMomentModel>> {
  @override
  Future<List<DailyMomentModel>> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return [];
    return ref.read(appRepositoryProvider).listTodayMoments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(appRepositoryProvider).listTodayMoments());
  }

  Future<DailyMomentModel> add({
    required String note,
    required String clientEventId,
  }) async {
    final moment = await ref.read(appRepositoryProvider).createMoment(
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
    final moment = await ref.read(appRepositoryProvider).updateMoment(
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

    await ref.read(appRepositoryProvider).deleteMoment(id);

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
      ref.read(appRepositoryProvider).uploadDailyMoodReport().then((_) {
        ref.invalidate(moodReportCheckInProvider);
        ref.invalidate(moodStatusViewProvider);
        ref.invalidate(moodPeriodSummaryProvider);
      }).catchError((_) {}),
    );
  }
}
