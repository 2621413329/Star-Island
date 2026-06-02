import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/mood_island_config.dart';
import '../core/theme/mood_theme.dart';
import '../core/utils/client_moment_factory.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';

final moodIslandRegistryProvider = AsyncNotifierProvider<MoodIslandRegistryNotifier, MoodIslandRegistry>(
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

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfileModel?>(ProfileNotifier.new);

final todayMomentsProvider = AsyncNotifierProvider<TodayMomentsNotifier, List<DailyMomentModel>>(
  TodayMomentsNotifier.new,
);

final moodPaletteProvider = Provider<MoodPalette>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  return paletteForMood(profile?.todayMood);
});

class ProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  @override
  Future<UserProfileModel?> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return null;
    return ref.read(appRepositoryProvider).getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(appRepositoryProvider).getProfile());
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
    state = await AsyncValue.guard(() => ref.read(appRepositoryProvider).listTodayMoments());
  }

  Future<DailyMomentModel> add({
    required List<String> eventTags,
    required String emotionTag,
    String? note,
  }) async {
    final profile = ref.read(profileProvider).valueOrNull;
    final style = profile?.companionStyle ?? 'chibi';
    DailyMomentModel moment;
    try {
      moment = await ref.read(appRepositoryProvider).createMoment(
            eventTags: eventTags,
            emotionTag: emotionTag,
            note: note,
          );
    } catch (_) {
      moment = ClientMomentFactory.build(
        eventTags: eventTags,
        emotionTag: emotionTag,
        note: note,
        companionStyle: style,
      );
    }
    final current = state.valueOrNull ?? [];
    state = AsyncData([moment, ...current]);
    return moment;
  }
}
