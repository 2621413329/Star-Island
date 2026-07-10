import 'daily_mood_prompt_store.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/growth_tag_catalog_cache.dart';
import '../../data/models/growth_tag_models.dart';

abstract class UserAppPreferencesPatcher {
  Future<void> patchAppPreferences(Map<String, dynamic> payload);
}

/// 将用户轻量偏好同步到后端 [user_profiles.app_preferences]。
class UserAppPreferencesSync {
  UserAppPreferencesSync({UserAppPreferencesPatcher? patcher})
      : _patcher = patcher;

  final UserAppPreferencesPatcher? _patcher;

  static const growthIslandRulesKey = 'growth_island_rules_acknowledged';
  static const lastMoodPickKey = 'last_daily_mood_pick_date';
  static const lastStoryPromptKey = 'last_daily_story_prompt_date';
  static const storyIslandCategoryOrderKey = 'story_island_category_order';
  static const customGrowthTagCatalogKey = 'custom_growth_tag_catalog';
  static const _customGrowthTagCatalogDirtyKey =
      'custom_growth_tag_catalog_dirty_v1';

  Future<void> hydrateFromServer(
    Map<String, dynamic>? prefs, {
    String? userId,
  }) async {
    final hasPendingCustomCatalog = await _hasPendingCustomGrowthTagCatalog();
    if (prefs == null || prefs.isEmpty) {
      if (!hasPendingCustomCatalog) {
        await GrowthTagCatalogCache.clearCustom();
      }
      return;
    }
    final sp = await SharedPreferences.getInstance();

    final rules = prefs[growthIslandRulesKey];
    if (rules is bool && rules) {
      await sp.setBool('growth_island_rules_acknowledged', true);
    }

    final moodDate = prefs[lastMoodPickKey];
    if (moodDate is String && moodDate.isNotEmpty) {
      await sp.setString(DailyMoodPromptStore.moodKeyFor(userId), moodDate);
    }

    final storyDate = prefs[lastStoryPromptKey];
    if (storyDate is String && storyDate.isNotEmpty) {
      await sp.setString(DailyMoodPromptStore.storyKeyFor(userId), storyDate);
    }

    if (hasPendingCustomCatalog) {
      await syncPendingCustomGrowthTagCatalog();
    } else {
      final customCatalog = prefs[customGrowthTagCatalogKey];
      if (customCatalog is List && customCatalog.isNotEmpty) {
        final catalog = customCatalog
            .whereType<Map>()
            .map((item) => GrowthTagCategoryModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();
        await GrowthTagCatalogCache.saveCustom(catalog);
      } else {
        await GrowthTagCatalogCache.clearCustom();
      }
    }
  }

  Future<void> markGrowthIslandRulesAcknowledged() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('growth_island_rules_acknowledged', true);
    await _patch({growthIslandRulesKey: true});
  }

  Future<void> markMoodPickedToday({String? userId}) async {
    final today = DailyMoodPromptStore.todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(DailyMoodPromptStore.moodKeyFor(userId), today);
    await _patch({lastMoodPickKey: today});
  }

  Future<void> markStoryPromptedToday({String? userId}) async {
    final today = DailyMoodPromptStore.todayIso();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(DailyMoodPromptStore.storyKeyFor(userId), today);
    await _patch({lastStoryPromptKey: today});
  }

  Future<void> saveStoryIslandCategoryOrder(List<String> order) async {
    await _patch({storyIslandCategoryOrderKey: order});
  }

  Future<void> saveCustomGrowthTagCatalog(
    List<Map<String, dynamic>> catalog,
  ) async {
    final models = catalog
        .map((item) => GrowthTagCategoryModel.fromJson(item))
        .toList(growable: false);
    await GrowthTagCatalogCache.saveCustom(models);
    await _markCustomGrowthTagCatalogDirty(catalog);
    await syncPendingCustomGrowthTagCatalog();
  }

  Future<void> syncPendingCustomGrowthTagCatalog() async {
    if (!await _hasPendingCustomGrowthTagCatalog()) return;
    final catalog = await GrowthTagCatalogCache.loadCustom();
    final payload = catalog.isNotEmpty
        ? catalog.map((category) => category.toJson()).toList()
        : await _pendingCustomGrowthTagCatalogPayload();
    final patched = await _tryPatch({customGrowthTagCatalogKey: payload});
    if (patched) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_customGrowthTagCatalogDirtyKey);
    }
  }

  Future<void> _patch(Map<String, dynamic> payload) async {
    await _tryPatch(payload);
  }

  Future<bool> _tryPatch(Map<String, dynamic> payload) async {
    final patcher = _patcher;
    if (patcher == null) return false;
    try {
      await patcher.patchAppPreferences(payload);
      return true;
    } catch (_) {
      // 离线时保留本地缓存，下次登录 hydrate 会与服务端合并。
      return false;
    }
  }

  Future<bool> _hasPendingCustomGrowthTagCatalog() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(_customGrowthTagCatalogDirtyKey);
  }

  Future<void> _markCustomGrowthTagCatalogDirty(
    List<Map<String, dynamic>> catalog,
  ) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_customGrowthTagCatalogDirtyKey, jsonEncode(catalog));
  }

  Future<List<Map<String, dynamic>>>
      _pendingCustomGrowthTagCatalogPayload() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_customGrowthTagCatalogDirtyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
