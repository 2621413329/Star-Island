/// API 时间解析：无时区偏移时按 UTC 理解（与后端 timezone-aware 字段一致）。
DateTime? parseApiDateTime(Object? raw) {
  if (raw == null) return null;
  if (raw is int) {
    final ms = raw > 100000000000 ? raw : raw * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  if (raw is num) {
    return parseApiDateTime(raw.toInt());
  }

  final text = raw.toString().trim();
  if (text.isEmpty) return null;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed;

  // 无偏移的 ISO 字符串：按 UTC 解释，避免先当本地再 toUtc 造成日期偏移。
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

/// 会员有效期展示：本地日历日。
String formatMembershipExpireDate(DateTime utcOrLocal) {
  final local = utcOrLocal.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString();
  final d = local.day.toString();
  return '$y年$m月$d日';
}
