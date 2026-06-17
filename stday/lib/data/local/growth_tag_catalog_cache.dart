import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/growth_tag_models.dart';

/// 成长标签库本地缓存，供离线展示与 API 失败时回退。
class GrowthTagCatalogCache {
  GrowthTagCatalogCache._();

  static const _prefsKey = 'growth_tag_catalog_v1';

  static Future<List<GrowthTagCategoryModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => GrowthTagCategoryModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<GrowthTagCategoryModel> catalog) async {
    if (catalog.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(catalog.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
