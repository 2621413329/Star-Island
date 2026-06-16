import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final storyReminderServiceProvider = Provider<StoryReminderService>((ref) {
  return StoryReminderService.instance;
});

/// 本地提醒：早晨 / 中午 / 晚上引导记录成长故事。
class StoryReminderService {
  StoryReminderService._();

  static final StoryReminderService instance = StoryReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _customIdBase = 2000;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> scheduleFromPreferences(Map<String, dynamic> prefs) async {
    await initialize();
    await _plugin.cancelAll();
    if (prefs['reminders_enabled'] == false) return;

    final records = _parseCustomReminders(prefs);
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record['enabled'] == false) continue;
      final time = record['time'] as String? ?? '08:00';
      final text = record['text'] as String? ?? '记录今天的成长故事';
      final id = _notificationIdFor(record, i);
      await _scheduleIfEnabled(
        enabled: true,
        id: id,
        time: time,
        title: text,
        body: '打开小岛，写下今天的故事',
      );
    }
  }

  List<Map<String, dynamic>> _parseCustomReminders(Map<String, dynamic> prefs) {
    final raw = prefs['custom_reminders'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  Future<void> _scheduleIfEnabled({
    required bool enabled,
    required int id,
    required String time,
    required String title,
    required String body,
  }) async {
    if (!enabled) return;
    final parts = time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

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

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'story_reminders',
        '成长记录提醒',
        channelDescription: '引导你记录每日成长故事',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
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
}
