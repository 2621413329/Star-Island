import 'package:flutter/services.dart';

const reminderIconAssetDir = 'assets/images/companion/times';

/// 从 [reminderIconAssetDir] 扫描提醒图标资源（PNG / SVG / WebP）。
class ReminderIconAssetCatalog {
  ReminderIconAssetCatalog._(this._assets);

  static Future<ReminderIconAssetCatalog>? _future;

  final List<String> _assets;

  static Future<ReminderIconAssetCatalog> load() {
    return _future ??= _load();
  }

  static Future<ReminderIconAssetCatalog> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) =>
            path.startsWith('$reminderIconAssetDir/') && _isSupported(path))
        .toList()
      ..sort();
    return ReminderIconAssetCatalog._(assets);
  }

  List<String> get allAssetPaths => List.unmodifiable(_assets);

  String get defaultIcon =>
      _assets.isNotEmpty ? _assets.first : '$reminderIconAssetDir/morning.svg';

  bool contains(String assetPath) => _assets.contains(assetPath);

  static bool _isSupported(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.svg');
  }

  static String displayName(String assetPath) {
    final fileName = assetPath.substring(assetPath.lastIndexOf('/') + 1);
    final dot = fileName.lastIndexOf('.');
    final stem = dot == -1 ? fileName : fileName.substring(0, dot);
    return stem.replaceAll('-', ' ').replaceAll('_', ' ');
  }
}
