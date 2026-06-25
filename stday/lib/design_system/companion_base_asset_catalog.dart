import 'package:flutter/services.dart';

import '../core/constants/companion_base_asset.dart';

/// 从 manifest 同步解析 companion/base PNG，避免逐帧尝试多条路径导致加载慢。
class CompanionBaseAssetCatalog {
  CompanionBaseAssetCatalog._(this._assetsByStem);

  static Future<CompanionBaseAssetCatalog>? _future;

  final Map<String, String> _assetsByStem;

  static Future<CompanionBaseAssetCatalog> load() {
    return _future ??= _load();
  }

  static Future<CompanionBaseAssetCatalog> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final byStem = <String, String>{};
    for (final path in manifest.listAssets()) {
      if (!path.startsWith('$companionBaseAssetDir/') ||
          (!path.toLowerCase().endsWith('.png') &&
              !path.toLowerCase().endsWith('.webp'))) {
        continue;
      }
      final fileName = path.substring(path.lastIndexOf('/') + 1);
      final dot = fileName.lastIndexOf('.');
      if (dot <= 0) continue;
      byStem[fileName.substring(0, dot).toLowerCase()] = path;
    }
    return CompanionBaseAssetCatalog._(byStem);
  }

  String? resolve({required String? gender, required String? assetId}) {
    for (final path in companionBaseAssetCandidates(
      gender: gender,
      assetId: assetId,
      includePlaceholder: true,
    )) {
      final fileName = path.substring(path.lastIndexOf('/') + 1);
      final dot = fileName.lastIndexOf('.');
      if (dot <= 0) continue;
      final stem = fileName.substring(0, dot).toLowerCase();
      final hit = _assetsByStem[stem];
      if (hit != null) return hit;
    }
    return null;
  }
}
