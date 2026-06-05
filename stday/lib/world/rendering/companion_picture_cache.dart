import 'dart:ui';

import '../../design_system/companion_painter.dart';

/// 缓存 idle 状态下的小人 Picture，避免每帧重复矢量绘制。
class CompanionPictureCache {
  CompanionPictureCache._();

  static const int _maxEntries = 72;
  static final Map<String, Picture> _cache = {};

  static String key({
    required String style,
    required String expression,
    required String prop,
    required int tintArgb,
    required int widthPx,
    required int heightPx,
    String? gender,
  }) =>
      'v3|$style|$gender|$expression|$prop|$tintArgb|$widthPx|$heightPx';

  static Picture? get(String key) => _cache[key];

  static void put(String key, Picture picture) {
    if (_cache.containsKey(key)) return;
    while (_cache.length >= _maxEntries) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest)?.dispose();
    }
    _cache[key] = picture;
  }

  static Picture rasterize({
    required String style,
    required String expression,
    required String prop,
    required Color tint,
    required Color glow,
    required double width,
    required double height,
    String? gender,
  }) {
    final recorder = PictureRecorder();
    CompanionPainter(
      style: style,
      expression: expression,
      prop: prop,
      tint: tint,
      glow: glow,
      performanceLevel: 0,
      gender: gender,
    ).paint(Canvas(recorder), Size(width, height));
    return recorder.endRecording();
  }

  static void clear() {
    for (final picture in _cache.values) {
      picture.dispose();
    }
    _cache.clear();
  }
}
