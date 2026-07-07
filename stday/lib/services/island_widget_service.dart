import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'island_widget_models.dart';
import '../data/models/story_island_models.dart';
import '../world/preview/story_island_building_icon.dart';

class IslandWidgetService {
  IslandWidgetService._();

  static const appGroupId = 'group.com.xiaoerlcx.app.island';
  static const payloadKey = 'island_widget_payload';
  static const catalogKey = 'island_widget_catalog';
  static const buildingThumbKey = 'island_widget_building_thumb';
  static const iosWidgetKind = 'IslandQuickTaskWidget';
  static const androidWidgetName = 'IslandWidgetProvider';
  static const urlScheme = 'stday';

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static Future<void> initialize() async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await HomeWidget.registerInteractivityCallback(_backgroundCallback);
    } catch (e, st) {
      debugPrint('IslandWidget init failed: $e\n$st');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri == null) return;
    debugPrint('IslandWidget background callback: $uri');
  }

  static Future<void> saveCatalog(List<Map<String, dynamic>> catalog) async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await HomeWidget.saveWidgetData<String>(
        catalogKey,
        jsonEncode(catalog),
      );
    } catch (e, st) {
      debugPrint('IslandWidget catalog save failed: $e\n$st');
    }
  }

  static Future<void> saveCatalogFromIslands({
    required List<StoryIslandModel> ordered,
    required String todayDate,
    int? mainIslandUserLevel,
  }) async {
    if (ordered.isEmpty) return;
    final catalog = ordered.asMap().entries.map((entry) {
      return buildIslandWidgetPayload(
        island: entry.value,
        todayDate: todayDate,
        islandIndex: entry.key,
        islandTotal: ordered.length,
        orderedIslandIds: ordered.map((e) => e.id).toList(),
        mainIslandUserLevel: mainIslandUserLevel,
      ).toJson();
    }).toList();
    await saveCatalog(catalog);
  }

  static Future<void> syncPayload(IslandWidgetPayload payload) async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      final enriched = await _attachBuildingThumb(payload);
      await HomeWidget.saveWidgetData<String>(
        payloadKey,
        jsonEncode(enriched.toJson()),
      );
      await HomeWidget.updateWidget(
        iOSName: iosWidgetKind,
        androidName: androidWidgetName,
      );
    } catch (e, st) {
      debugPrint('IslandWidget sync failed: $e\n$st');
    }
  }

  static Future<IslandWidgetPayload> _attachBuildingThumb(
    IslandWidgetPayload payload,
  ) async {
    if (payload.isGrowthMain || payload.buildingPreviewLevel <= 0) {
      await HomeWidget.saveWidgetData<String>(buildingThumbKey, null);
      return payload.copyWith(resetBuildingThumbPath: true);
    }

    final assetPath = StoryIslandBuildingIcon.buildingAssetForLevel(
      payload.categoryId,
      payload.buildingPreviewLevel,
    );
    try {
      final data = await rootBundle.load(assetPath);
      final path = await HomeWidget.saveFile(
        buildingThumbKey,
        data.buffer.asUint8List(),
        extension: 'png',
        appGroupId: defaultTargetPlatform == TargetPlatform.iOS ? appGroupId : null,
      );
      return payload.copyWith(buildingThumbPath: path);
    } catch (e, st) {
      debugPrint('IslandWidget building thumb failed: $e\n$st');
      await HomeWidget.saveWidgetData<String>(buildingThumbKey, null);
      return payload.copyWith(resetBuildingThumbPath: true);
    }
  }

  static Future<void> clear() async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await HomeWidget.saveWidgetData<String>(buildingThumbKey, null);
      await HomeWidget.saveWidgetData<String>(catalogKey, null);
      await HomeWidget.saveWidgetData<String>(payloadKey, '');
      await HomeWidget.updateWidget(
        iOSName: iosWidgetKind,
        androidName: androidWidgetName,
      );
    } catch (e, st) {
      debugPrint('IslandWidget clear failed: $e\n$st');
    }
  }

  static String islandDeepLink({required String islandId}) {
    return '$urlScheme://widget/island?islandId=${Uri.encodeComponent(islandId)}';
  }

  static String taskDeepLink({
    required String islandId,
    required String taskId,
  }) {
    return '$urlScheme://widget/task?islandId=${Uri.encodeComponent(islandId)}&taskId=${Uri.encodeComponent(taskId)}';
  }

  static String cycleDeepLink({required String direction}) {
    return '$urlScheme://widget/cycle?direction=$direction';
  }

  static String quickRecordDeepLink({required String islandId}) {
    return '$urlScheme://widget/quick-record?islandId=${Uri.encodeComponent(islandId)}';
  }
}
