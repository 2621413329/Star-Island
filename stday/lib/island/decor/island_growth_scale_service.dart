/// 岛屿成长等级 → 全局缩放曲线（Lv1 萌芽 → Lv20 成熟）。
class IslandGrowthScaleService {
  const IslandGrowthScaleService();

  static const _anchors = <({int level, double scale})>[
    (level: 1, scale: 0.8),
    (level: 5, scale: 1.0),
    (level: 10, scale: 1.15),
    (level: 15, scale: 1.30),
    (level: 20, scale: 1.45),
  ];

  /// 按锚点分段 smoothstep 插值，避免等级跳变。
  double getLevelScale(int level) {
    final clamped = level.clamp(_anchors.first.level, _anchors.last.level);
    for (var i = 0; i < _anchors.length - 1; i++) {
      final start = _anchors[i];
      final end = _anchors[i + 1];
      if (clamped <= end.level) {
        final span = end.level - start.level;
        if (span <= 0) return start.scale;
        final t = (clamped - start.level) / span;
        final smooth = t * t * (3 - 2 * t);
        return start.scale + (end.scale - start.scale) * smooth;
      }
    }
    return _anchors.last.scale;
  }
}
