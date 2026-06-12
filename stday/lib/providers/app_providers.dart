import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/mood_island_config.dart';
import '../core/models/user_companion.dart';
import '../core/theme/mood_theme.dart';
import '../core/storage/user_app_preferences_sync.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';

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
  return paletteForMood(profile?.todayMood);
});

/// 当前登录用户的小人基础样貌，全应用统一引用此对象。
final userCompanionProvider = Provider<UserCompanion>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  return UserCompanion.fromProfile(profile);
});

class ProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  @override
  Future<UserProfileModel?> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return null;
    final profile = await ref.read(appRepositoryProvider).getProfile();
    await ref
        .read(userAppPreferencesSyncProvider)
        .hydrateFromServer(profile.appPreferences);
    return profile;
  }

  Future<void> refresh() async {
    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(
        () => ref.read(appRepositoryProvider).getProfile());
  }

  Future<UserProfileModel> updateNickname(String nickname) async {
    final p = await ref.read(appRepositoryProvider).updateNickname(nickname);
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
    required List<String> eventTags,
    required String emotionTag,
    required String clientEventId,
    String? note,
  }) async {
    final moment = await ref.read(appRepositoryProvider).createMoment(
          eventTags: eventTags,
          emotionTag: emotionTag,
          clientEventId: clientEventId,
          note: note,
        );
    await refresh();
    await ref.read(profileProvider.notifier).refresh();
    final synced = state.valueOrNull ?? [];
    return synced.firstWhere((m) => m.id == moment.id, orElse: () => moment);
  }

  Future<DailyMomentModel> updateMoment({
    required String id,
    required List<String> eventTags,
    required String emotionTag,
    String? note,
  }) async {
    final moment = await ref.read(appRepositoryProvider).updateMoment(
          id: id,
          eventTags: eventTags,
          emotionTag: emotionTag,
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
  }
}
