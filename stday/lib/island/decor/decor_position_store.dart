import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// 装饰落点持久化：升级解锁时随机落点，之后固定不变。
class DecorPositionStore {
  DecorPositionStore({this.userId});

  final String? userId;
  static const _prefix = 'decor_pos_v1';

  String _key(String decorId) {
    final uid = userId ?? 'guest';
    return '$_prefix:$uid:$decorId';
  }

  Future<Map<String, Offset>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_prefix:${userId ?? 'guest'}:';
    final result = <String, Offset>{};
    for (final entry in prefs.getKeys()) {
      if (!entry.startsWith(prefix)) continue;
      final decorId = entry.substring(prefix.length);
      final raw = prefs.getString(entry);
      final pos = _parse(raw);
      if (pos != null) result[decorId] = pos;
    }
    return result;
  }

  Future<void> save(String decorId, Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(decorId),
      '${position.dx.toStringAsFixed(4)},${position.dy.toStringAsFixed(4)}',
    );
  }

  Offset? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final x = double.tryParse(parts[0]);
    final y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;
    return Offset(x, y);
  }
}
