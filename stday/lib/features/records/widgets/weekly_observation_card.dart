import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mood_theme.dart';
import '../../../providers/growth_observation_provider.dart';
import '../../../design_system/island_decorations.dart';

class WeeklyObservationCard extends ConsumerWidget {
  const WeeklyObservationCard({super.key, required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentGrowthObservationProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (obs) {
        if (obs.weeklyHint.isEmpty) return const SizedBox.shrink();
        return IslandGlassCard(
          palette: palette,
          padding: const EdgeInsets.all(14),
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
              const SizedBox(height: 8),
              Text(
                obs.weeklyHint,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: palette.primary.withValues(alpha: 0.85),
                ),
              ),
              if (obs.stressDirections.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: obs.stressDirections.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.primary.withValues(alpha: 0.75),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
