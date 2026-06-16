import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  static const _androidChannelId = 'story_reminders_v2';
  static const _androidChannelName = '成长记录提醒';
  static const _prefsCacheKey = 'story_reminder_prefs_cache_v1';

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: '引导你记录每日成长故事',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
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

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: '引导你记录每日成长故事',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          ticker: '成长记录提醒',
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

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
      final record = records[i];
      if (!_isEnabled(record['enabled'])) continue;
      final time = record['time'] as String? ?? '08:00';
      final text = record['text'] as String? ?? '记录今天的成长故事';
      final id = _notificationIdFor(record, i);
      final ok = await _scheduleIfEnabled(
        enabled: true,
        id: id,
        time: time,
        title: text,
        body: '打开小岛，写下今天的故事',
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

  static bool _isEnabled(dynamic value) {
    if (value == false || value == 0 || value == 'false') return false;
    return true;
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
    var canExact = await android.canScheduleExactNotifications();
    if (canExact != true) {
      await android.requestExactAlarmsPermission();
      canExact = await android.canScheduleExactNotifications();
    }
    if (canExact == true) {
      modes.add(AndroidScheduleMode.exactAllowWhileIdle);
    }
    modes.add(AndroidScheduleMode.alarmClock);
    modes.add(AndroidScheduleMode.inexactAllowWhileIdle);
    return modes;
  }

  Future<bool> _scheduleIfEnabled({
    required bool enabled,
    required int id,
    required String time,
    required String title,
    required String body,
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

    final modes = await _androidScheduleModes();
    Object? lastError;
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          _notificationDetails,
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

  Future<void> showTestNotification() async {
    await initialize();
    await requestPermission();
    await _plugin.show(
      1999,
      '提醒测试',
      '若能看到这条通知，说明推送通道已正常工作',
      _notificationDetails,
    );
  }
}
