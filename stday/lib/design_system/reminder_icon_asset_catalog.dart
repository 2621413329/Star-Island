import 'package:flutter/services.dart';

const reminderIconAssetDir = 'assets/images/companion/times';

/// 当前应用图标。每日提醒的通知和默认图标都用这一张。
const reminderBrandIconAsset = 'assets/app_icon.png';

const reminderCuratedIconAssets = <String>[
  '$reminderIconAssetDir/morning.svg',
  '$reminderIconAssetDir/noon.svg',
  '$reminderIconAssetDir/evening.svg',
  '$reminderIconAssetDir/bell.svg',
  '$reminderIconAssetDir/book.svg',
  '$reminderIconAssetDir/star.svg',
];

/// 旧图标、表情和兴趣道具图都换成当前应用图标。
String reminderIconAssetOrBrand(String raw) {
  final value = raw.trim();
  if (value == reminderBrandIconAsset ||
      reminderCuratedIconAssets.contains(value)) {
    return value;
  }
  return reminderBrandIconAsset;
}

/// 提醒可选图标：当前应用图标，以及早晚时段用的少量图形。
class ReminderIconAssetCatalog {
  ReminderIconAssetCatalog._(this._assets);

  static Future<ReminderIconAssetCatalog>? _future;

  final List<String> _assets;

  static Future<ReminderIconAssetCatalog> load() {
    return _future ??= _load();
  }

  static Future<ReminderIconAssetCatalog> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final curated = manifest
        .listAssets()
        .where((path) => reminderCuratedIconAssets.contains(path))
        .toList()
      ..sort();
    return ReminderIconAssetCatalog._([
      reminderBrandIconAsset,
      ...curated,
    ]);
  }

  List<String> get allAssetPaths => List.unmodifiable(_assets);

  String get defaultIcon => reminderBrandIconAsset;

  bool contains(String assetPath) => _assets.contains(assetPath);

  static String displayName(String assetPath) {
    final fileName = assetPath.substring(assetPath.lastIndexOf('/') + 1);
    final dot = fileName.lastIndexOf('.');
    final stem = dot == -1 ? fileName : fileName.substring(0, dot);
    return stem.replaceAll('-', ' ').replaceAll('_', ' ');
  }
}
