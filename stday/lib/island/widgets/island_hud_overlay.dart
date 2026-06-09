import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import '../../island/config/island_visual_config.dart';

/// 叠在岛景上的 HUD：等级、连续天、进度、心情入口。
class IslandHudOverlay extends StatelessWidget {
  const IslandHudOverlay({
    super.key,
    required this.summary,
    required this.todayMoodLabel,
    this.onRecordTap,
    this.onMoodTap,
  });

  final GrowthSummary summary;
  final String todayMoodLabel;
  final VoidCallback? onRecordTap;
  final VoidCallback? onMoodTap;

  @override
  Widget build(BuildContext context) {
    final tier = IslandVisualConfig.prosperityTierFromLevel(summary.level);
    final tierLabel = IslandVisualConfig.prosperityLabel(tier);
    final next = summary.nextLevel;
    final need = summary.xpForNextLevel;
    final progress = need != null && need > 0
        ? (summary.xpIntoLevel / need).clamp(0.0, 1.0)
        : 1.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.pageHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TopLeftCard(summary: summary, tierLabel: tierLabel)),
                const SizedBox(width: 8),
                _MoodChip(
                  label: todayMoodLabel,
                  onTap: onMoodTap,
                ),
              ],
            ),
            const Spacer(),
            _BottomProgress(
              summary: summary,
              progress: progress,
              next: next,
              need: need,
              onRecordTap: onRecordTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopLeftCard extends StatelessWidget {
  const _TopLeftCard({required this.summary, required this.tierLabel});

  final GrowthSummary summary;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lv.${summary.level} ${summary.levelTitle}',
            style: appTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '🔥 ${summary.streakDays} 天 · ✦ ${summary.growthValue}',
            style: appTextStyle(fontSize: 11, color: const Color(0xFF8C7B6B)),
          ),
          Text(
            tierLabel,
            style: appTextStyle(
              fontSize: 10,
              color: const Color(0xFF8C7B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              const Text('☀', style: TextStyle(fontSize: 18)),
              Text(
                label,
                style: appTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D4E44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomProgress extends StatelessWidget {
  const _BottomProgress({
    required this.summary,
    required this.progress,
    required this.next,
    required this.need,
    this.onRecordTap,
  });

  final GrowthSummary summary;
  final double progress;
  final int? next;
  final int? need;
  final VoidCallback? onRecordTap;

  @override
  Widget build(BuildContext context) {
    final hint = next != null && need != null && need! > 0
        ? '距离 Lv.$next 还需 ${(need! - summary.xpIntoLevel).clamp(0, need!)} 成长值'
        : '你的成长世界正在变得繁荣';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hint,
                style: appTextStyle(fontSize: 12, color: const Color(0xFF5D4E44)),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8DDD4),
                  color: const Color(0xFFE8A87C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (onRecordTap != null)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: onRecordTap,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('记录今天'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5D4E44),
                backgroundColor: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
