import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/utils/story_island_visual.dart';

/// 群岛地图岛屿标签：主岛白胶囊治愈风；副岛左圆标 + 半透明胶囊。
class FloatingIslandLabel extends StatelessWidget {
  const FloatingIslandLabel({
    super.key,
    required this.name,
    required this.level,
    this.highlighted = false,
    this.depth = 0,
    this.isMain = false,
    this.categoryId,
  });

  final String name;
  final int level;
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
      categoryId: categoryId,
      depth: depth,
    );
  }
}

class _MainIslandNameplate extends StatelessWidget {
  const _MainIslandNameplate({required this.name, required this.level});

  final String name;
  final int level;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF5FAE72);
    final label = level > 0 ? '$name · Lv.$level' : name;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7CB8E8).withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, size: 12, color: green.withValues(alpha: 0.95)),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: green,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 8,
          top: -7,
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: const Color(0xFFFFC857).withValues(alpha: 0.95),
            shadows: const [
              Shadow(color: Color(0x55FFB300), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryIslandNameplate extends StatelessWidget {
  const _StoryIslandNameplate({
    required this.name,
    required this.level,
    required this.depth,
    this.categoryId,
  });

  final String name;
  final int level;
  final double depth;
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTint(categoryId);
    final status = level > 0 ? 'Lv.$level' : '待开启';
    final label = '$name · $status';
    final icon = storyIslandCategoryIcon(categoryId ?? '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: tint,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22 + depth * 0.04),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: appTextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.96),
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryTint(String? categoryId) {
    return switch (categoryId) {
      'study' => const Color(0xFF9B7BFF),
      'health' => const Color(0xFF5FCF8A),
      'work' => const Color(0xFF5BA8FF),
      'social' => const Color(0xFFFF7A7A),
      'creation' => const Color(0xFFFF8FB8),
      'life' => const Color(0xFF7BC47F),
      'finance' || 'wealth' => const Color(0xFFFFC857),
      'emotion' => const Color(0xFFFF9AD5),
      'achievement' || 'milestone' => const Color(0xFFFFB347),
      _ => const Color(0xFF7AA8D8),
    };
  }
}
