import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// 群岛名称：磨砂白胶囊，主岛与副岛同一套语气。
class FloatingIslandLabel extends StatelessWidget {
  const FloatingIslandLabel({
    super.key,
    required this.name,
    required this.level,
    this.opened = false,
    this.highlighted = false,
    this.depth = 0,
    this.isMain = false,
    this.categoryId,
  });

  final String name;
  final int level;

  /// 副岛是否已开启（有记录/成长值 > 0）。未达 Lv1 时 [level] 可为 0。
  final bool opened;
  final bool highlighted;
  final double depth;
  final bool isMain;
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    if (isMain) return _MainIslandNameplate(name: name, level: level);
    return _StoryIslandNameplate(
      name: name,
      level: level,
      opened: opened,
      categoryId: categoryId,
    );
  }
}

class _GlassNameplate extends StatelessWidget {
  const _GlassNameplate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.96)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x243A6284),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: child,
      ),
    );
  }
}

class _MainIslandNameplate extends StatelessWidget {
  const _MainIslandNameplate({required this.name, required this.level});

  final String name;
  final int level;

  @override
  Widget build(BuildContext context) {
    return _GlassNameplate(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            softWrap: false,
            style: appTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3C5870),
              letterSpacing: 0.2,
            ),
          ),
          if (level > 0) ...[
            const SizedBox(width: 6),
            Text(
              'Lv.$level',
              maxLines: 1,
              softWrap: false,
              style: appTextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8AA0B4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryIslandNameplate extends StatelessWidget {
  const _StoryIslandNameplate({
    required this.name,
    required this.level,
    required this.opened,
    this.categoryId,
  });

  final String name;
  final int level;
  final bool opened;
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTint(categoryId);
    // 已开启但未达 Lv1 → Lv.0；无记录才显示待开启。
    final status = level > 0 ? 'Lv.$level' : (opened ? 'Lv.0' : '待开启');

    return _GlassNameplate(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            maxLines: 1,
            softWrap: false,
            style: appTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C5870),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            maxLines: 1,
            softWrap: false,
            style: appTextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8AA0B4),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryTint(String? categoryId) {
    return switch (categoryId) {
      'study' => const Color(0xFF9B7BFF),
      'health' => const Color(0xFF5FCF8A),
      'work' => const Color(0xFF5BA8FF),
      'social' => const Color(0xFFFF8A8A),
      'creation' => const Color(0xFFFF8FB8),
      'life' => const Color(0xFF7BC47F),
      'finance' || 'wealth' => const Color(0xFFE2B15A),
      'emotion' => const Color(0xFFFF9AD5),
      'achievement' || 'milestone' => const Color(0xFFFFB347),
      _ => const Color(0xFF7AA8D8),
    };
  }
}
