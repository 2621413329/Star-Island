import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_record.dart';
import 'reminder_notification_bitmap.dart';

final storyReminderServiceProvider = Provider<StoryReminderService>((ref) {
  return StoryReminderService.instance;
});

class ReminderScheduleStatus {
  const ReminderScheduleStatus({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;

  bool get readyForScheduling => notificationsGranted;
}

/// 本地提醒：自定义时间与文案，引导记录成长故事。
class StoryReminderService {
  StoryReminderService._();

  static final StoryReminderService instance = StoryReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _customIdBase = 2000;
  static const _androidChannelId = 'story_reminders_v3';
  static const _androidChannelName = '成长记录提醒';
  static const _androidNotificationSound =
      UriAndroidNotificationSound('content://settings/system/notification_sound');
  static const _prefsCacheKey = 'story_reminder_prefs_cache_v1';

  static const _androidNotificationIcon = 'ic_notification';
  static const _defaultIconAsset =
      'assets/images/companion/times/morning.svg';

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_androidNotificationIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      windows: WindowsInitializationSettings(
        appName: '星屿',
        appUserModelId: 'com.stday.stday',
        guid: 'a7f3c2e1-9b4d-4f6a-8c2e-1d5b9a3e7f04',
      ),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: '引导你记录每日成长故事',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          sound: _androidNotificationSound,
        ),
      );
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      return;
    } catch (e) {
      debugPrint('StoryReminder: timezone lookup failed: $e');
    }
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final locationName = hours == 0
        ? 'UTC'
        : (hours > 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${hours.abs()}');
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      debugPrint('StoryReminder: timezone fallback failed: $e');
    }
  }

  Future<NotificationDetails> _notificationDetailsFor(String iconAsset) async {
    try {
      final largeIcon =
          await ReminderNotificationBitmap.instance.forAsset(iconAsset);
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: '引导你记录每日成长故事',
          importance: Importance.max,
          priority: Priority.high,
          icon: _androidNotificationIcon,
          largeIcon: largeIcon,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          sound: _androidNotificationSound,
          ticker: '成长记录提醒',
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } catch (e, st) {
      debugPrint('StoryReminder: notification icon failed: $e\n$st');
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: '引导你记录每日成长故事',
          importance: Importance.max,
          priority: Priority.high,
          icon: _androidNotificationIcon,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          sound: _androidNotificationSound,
          ticker: '成长记录提醒',
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    }
  }

  Future<void> scheduleFromPreferences(
    Map<String, dynamic> prefs, {
    bool persistCache = true,
  }) async {
    await initialize();
    await _configureLocalTimeZone();
    if (persistCache) {
      await _cachePreferences(prefs);
    }

    await _plugin.cancelAll();
    if (prefs['reminders_enabled'] == false) return;

    final records = _parseCustomReminders(prefs);
    var scheduledCount = 0;
    for (var i = 0; i < records.length; i++) {
      final record = ReminderRecord.fromJson(records[i]);
      if (!record.enabled) continue;
      final id = _notificationIdFor(records[i], i);
      final ok = await _scheduleIfEnabled(
        enabled: true,
        id: id,
        time: record.time,
        title: record.text,
        body: '打开小岛，写下今天的故事',
        iconAsset: record.iconAsset,
      );
      if (ok) scheduledCount++;
    }
    debugPrint('StoryReminder: scheduled $scheduledCount reminder(s)');
  }

  Future<void> rescheduleFromCacheIfEnabled() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_prefsCacheKey);
      if (raw == null || raw.isEmpty) return;
      final prefs = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (prefs['reminders_enabled'] == false) return;
      await scheduleFromPreferences(prefs, persistCache: false);
    } catch (e, st) {
      debugPrint('StoryReminder: rescheduleFromCache failed: $e\n$st');
    }
  }

  Future<void> _cachePreferences(Map<String, dynamic> prefs) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsCacheKey, jsonEncode(prefs));
    } catch (e) {
      debugPrint('StoryReminder: cache prefs failed: $e');
    }
  }

  List<Map<String, dynamic>> _parseCustomReminders(Map<String, dynamic> prefs) {
    final raw = prefs['custom_reminders'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [
      if (prefs['reminder_morning_enabled'] != false)
        {
          'id': 'legacy_morning',
          'time': prefs['wake_time'] ?? '08:00',
          'text': '今天最重要的一件事是什么？',
          'enabled': true,
        },
      if (prefs['reminder_noon_enabled'] != false)
        {
          'id': 'legacy_noon',
          'time': prefs['lunch_time'] ?? '12:30',
          'text': '今天进展如何？',
          'enabled': true,
        },
      if (prefs['reminder_evening_enabled'] != false)
        {
          'id': 'legacy_evening',
          'time': prefs['work_end_time'] ?? '21:00',
          'text': '今天最值得记录的一件事是什么？',
          'enabled': true,
        },
    ];
  }


  int _notificationIdFor(Map<String, dynamic> record, int index) {
    final idRaw = record['id'];
    if (idRaw is String && idRaw.isNotEmpty) {
      return _customIdBase + (idRaw.hashCode & 0x7FFFFFFF) % 9000;
    }
    return _customIdBase + index;
  }

  Future<List<AndroidScheduleMode>> _androidScheduleModes() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return const [AndroidScheduleMode.inexactAllowWhileIdle];
    }

    final modes = <AndroidScheduleMode>[];
    // 鸿蒙 / 华为 / 小米等国产 ROM 对 exact 闹钟限制严，alarmClock 更可靠。
    modes.add(AndroidScheduleMode.alarmClock);

    var canExact = await android.canScheduleExactNotifications();
    if (canExact != true) {
      await android.requestExactAlarmsPermission();
      canExact = await android.canScheduleExactNotifications();
    }
    if (canExact == true) {
      modes.add(AndroidScheduleMode.exactAllowWhileIdle);
    }
    modes.add(AndroidScheduleMode.inexactAllowWhileIdle);
    return modes;
  }

  Future<bool> _scheduleIfEnabled({
    required bool enabled,
    required int id,
    required String time,
    required String title,
    required String body,
    required String iconAsset,
  }) async {
    if (!enabled) return false;
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = await _notificationDetailsFor(iconAsset);
    final modes = await _androidScheduleModes();
    Object? lastError;
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
          'StoryReminder: id=$id at ${scheduled.toIso8601String()} mode=$mode',
        );
        return true;
      } on PlatformException catch (e) {
        lastError = e;
        if (e.code == 'exact_alarms_not_permitted') continue;
        debugPrint('StoryReminder: schedule failed mode=$mode: $e');
      } catch (e) {
        lastError = e;
        debugPrint('StoryReminder: schedule failed mode=$mode: $e');
      }
    }
    debugPrint('StoryReminder: all modes failed for id=$id: $lastError');
    return false;
  }

  Future<ReminderScheduleStatus> ensureSchedulePermissions() async {
    if (kIsWeb) {
      return const ReminderScheduleStatus(
        notificationsGranted: false,
        exactAlarmsGranted: false,
      );
    }
    await initialize();
    final notificationsGranted = await requestPermission();
    var exactAlarmsGranted = true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      if (await android.canScheduleExactNotifications() != true) {
        await android.requestExactAlarmsPermission();
      }
      exactAlarmsGranted =
          await android.canScheduleExactNotifications() == true;
    }
    return ReminderScheduleStatus(
      notificationsGranted: notificationsGranted,
      exactAlarmsGranted: exactAlarmsGranted,
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<int> pendingReminderCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.where((item) => item.id >= _customIdBase).length;
  }

  Future<void> openSystemSettings() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    if (android != null &&
        await android.canScheduleExactNotifications() != true) {
      await android.requestExactAlarmsPermission();
    }
  }

  Future<void> showTestNotification({String? iconAsset}) async {
    await initialize();
    await requestPermission();
    final details = await _notificationDetailsFor(
      iconAsset ?? _defaultIconAsset,
    );
    await _plugin.show(
      1999,
      '提醒测试',
      '若能看到这条通知，说明推送通道已正常工作',
      details,
    );
  }
}
