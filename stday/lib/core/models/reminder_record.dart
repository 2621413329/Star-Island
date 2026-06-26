import 'dart:math';

/// 用户自定义本地提醒记录，持久化在 [app_preferences.custom_reminders]。
class ReminderRecord {
  const ReminderRecord({
    required this.id,
    required this.time,
    required this.text,
    required this.iconAsset,
    this.enabled = true,
  });

  final String id;
  final String time;
  final String text;
  final String iconAsset;
  final bool enabled;

  ReminderRecord copyWith({
    String? id,
    String? time,
    String? text,
    String? iconAsset,
    bool? enabled,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      time: time ?? this.time,
      text: text ?? this.text,
      iconAsset: iconAsset ?? this.iconAsset,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'text': text,
        'icon_asset': iconAsset,
        'enabled': enabled,
      };

  factory ReminderRecord.fromJson(Map<String, dynamic> json) {
    return ReminderRecord(
      id: json['id'] as String? ?? newReminderId(),
      time: json['time'] as String? ?? '08:30',
      text: json['text'] as String? ?? '记录今天的成长日常',
      iconAsset: json['icon_asset'] as String? ?? 'emoji:🔔',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  static String newReminderId() {
    final rand = Random().nextInt(0xFFFFFF);
    return '${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  static List<ReminderRecord> fromPreferences(Map<String, dynamic> prefs) {
    final raw = prefs['custom_reminders'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((item) => ReminderRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    return _legacyDefaults(prefs);
  }

  static List<Map<String, dynamic>> toJsonList(List<ReminderRecord> records) {
    return records.map((r) => r.toJson()).toList();
  }

  static List<ReminderRecord> _legacyDefaults(Map<String, dynamic> prefs) {
    final morningEnabled = prefs['reminder_morning_enabled'] != false;
    final noonEnabled = prefs['reminder_noon_enabled'] != false;
    final eveningEnabled = prefs['reminder_evening_enabled'] != false;
    return [
      ReminderRecord(
        id: 'legacy_morning',
        time: prefs['wake_time'] as String? ?? '08:30',
        text: '今天你打算做什么？',
        iconAsset: 'emoji:🌅',
        enabled: morningEnabled,
      ),
      ReminderRecord(
        id: 'legacy_noon',
        time: prefs['lunch_time'] as String? ?? '12:30',
        text: '今天进展如何？',
        iconAsset: 'emoji:☀️',
        enabled: noonEnabled,
      ),
      ReminderRecord(
        id: 'legacy_evening',
        time: prefs['work_end_time'] as String? ?? '21:30',
        text: '今天最值得记录的一件事是什么？',
        iconAsset: 'emoji:🌙',
        enabled: eveningEnabled,
      ),
    ];
  }
}
