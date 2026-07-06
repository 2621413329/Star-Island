import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'island_widget_models.dart';

class IslandWidgetService {
  IslandWidgetService._();

  static const appGroupId = 'group.com.xiaoerlcx.app.island';
  static const payloadKey = 'island_widget_payload';
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

  static Future<void> syncPayload(IslandWidgetPayload payload) async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
      await HomeWidget.saveWidgetData<String>(
        payloadKey,
        jsonEncode(payload.toJson()),
      );
      await HomeWidget.updateWidget(
        iOSName: iosWidgetKind,
        androidName: androidWidgetName,
      );
    } catch (e, st) {
      debugPrint('IslandWidget sync failed: $e\n$st');
    }
  }

  static Future<void> clear() async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(appGroupId);
      }
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

  static String quickRecordDeepLink({required String islandId}) {
    return '$urlScheme://widget/quick-record?islandId=${Uri.encodeComponent(islandId)}';
  }
}
