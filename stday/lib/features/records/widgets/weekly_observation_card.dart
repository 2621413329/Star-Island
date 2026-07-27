import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/moment_limits.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../providers/growth_observation_provider.dart';
import '../../../providers/member_provider.dart';
import '../../../core/membership/vip_guard.dart';
import '../../../design_system/expandable_preview_text.dart';
import '../../../design_system/island_decorations.dart';

class WeeklyObservationCard extends ConsumerWidget {
  const WeeklyObservationCard({super.key, required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVip = ref.watch(isVipProvider);

    if (!isVip) {
      return _WeeklyObservationFrame(
        child: VipFeatureMask(
          locked: true,
          message: '开通 VIP 查看本周小结',
          child: _LockedWeeklyObservationPreview(palette: palette),
        ),
      );
    }

    final async = ref.watch(weeklySummaryProvider);
    return async.when(
      loading: () => _WeeklyObservationFrame(
        child: IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '本周小结生成中…',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.primary.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => _WeeklyObservationFrame(
        child: IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.all(18),
          child: Text(
            '本周小结暂时不可用，稍后再来看看～',
            style: TextStyle(
              fontSize: 13,
              color: palette.primary.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
      data: (summary) {
        if (summary.weeklyHint.isEmpty) return const SizedBox.shrink();
        return _WeeklyObservationFrame(
          child: IslandGlassCard(
            palette: palette,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 18, color: palette.accent),
                    const SizedBox(width: 6),
                    Text(
                      '本周小结',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ExpandablePreviewText(
                  text: summary.weeklyHint,
                  collapsedMaxChars: weeklySummaryPreviewMaxChars,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: palette.primary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyObservationFrame extends StatelessWidget {
  const _WeeklyObservationFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 118),
      child: child,
    );
  }
}

class _LockedWeeklyObservationPreview extends StatelessWidget {
  const _LockedWeeklyObservationPreview({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: palette.accent),
              const SizedBox(width: 6),
              Text(
                '本周小结',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '这一周的日常会被整理成一段小结，帮你看见反复出现的情绪、值得保留的力量，以及下一步可以轻轻尝试的方向。',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: palette.primary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
