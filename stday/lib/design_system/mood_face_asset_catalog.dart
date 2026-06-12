import 'package:flutter/services.dart';

import '../core/constants/catalog.dart';
/// 从 `assets/images/mood_faces/` 目录读取 PNG。
/// 男生优先 `man_<moodId>.png`，女生优先 `woman_<moodId>.png`，否则回退 `<moodId>.png`。
class MoodFaceAssetCatalog {
  MoodFaceAssetCatalog._(this._assetsByStem);

  static Future<MoodFaceAssetCatalog>? _future;

  final Map<String, String> _assetsByStem;

  static Future<MoodFaceAssetCatalog> load() {
    return _future ??= _load();
  }

  static String? genderPrefix(String? gender) {
    return switch (gender?.trim().toLowerCase()) {
      'female' || 'girl' || '女' => 'woman',
      'male' || '男' => 'man',
      _ => null,
    };
  }

  static Future<MoodFaceAssetCatalog> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final byStem = <String, String>{};
    for (final path in manifest.listAssets()) {
      if (!path.startsWith('$moodFaceAssetDir/') ||
          !path.toLowerCase().endsWith('.png')) {
        continue;
      }
      final fileName = path.substring(path.lastIndexOf('/') + 1);
      final stem = fileName.substring(0, fileName.length - 4).toLowerCase();
      byStem[stem] = path;
    }
    return MoodFaceAssetCatalog._(byStem);
  }

  /// 按心情 id 查找图片，例如 `happy` + 男生 -> `man_happy.png`。
  String? resolve(String moodId, {String? gender}) {
    final id = moodId.trim().toLowerCase();
    final prefix = genderPrefix(gender);
    if (prefix != null) {
      final gendered = _assetsByStem['${prefix}_$id'];
      if (gendered != null) return gendered;
    }
    final generic = _assetsByStem[id];
    if (generic != null) return generic;
    return _assetsByStem['man_$id'] ?? _assetsByStem['woman_$id'];
  }

  List<String> get allAssetPaths =>
      _assetsByStem.values.toList()..sort((a, b) => a.compareTo(b));
}
