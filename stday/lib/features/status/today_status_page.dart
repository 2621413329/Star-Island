import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';
import '../../providers/app_providers.dart';

class TodayStatusPage extends ConsumerWidget {
  const TodayStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final momentsAsync = ref.watch(todayMomentsProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: momentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (moments) {
              final moodCounts = <String, int>{};
              for (final m in moments) {
                moodCounts[m.emotionTag] = (moodCounts[m.emotionTag] ?? 0) + 1;
              }
              final total = moments.isEmpty ? 1 : moments.length;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('今日状态', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('今天记录了什么'),
                  const SizedBox(height: 24),
                  if (moments.isEmpty)
                    const Text('今天还没有留下故事')
                  else
                    ...moments.map((m) {
                      final mood = moodById(m.emotionTag);
                      return IslandGlassCard(
                        palette: palette,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CustomPaint(
                                painter: MoodFacePainter(type: mood.faceType, color: mood.color),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(primaryStoryLabel(m.eventTags),
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(m.note ?? m.eventTags.join(' · '),
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF8C7B6B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 28),
                  const Text('今日心情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ...moodCounts.entries.map((e) {
                    final mood = moodById(e.key);
                    final pct = (e.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CustomPaint(
                              painter: MoodFacePainter(type: mood.faceType, color: mood.color, strokeWidth: 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(mood.label, style: TextStyle(color: mood.color, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: e.value / total,
                                minHeight: 22,
                                backgroundColor: palette.primaryContainer,
                                color: mood.color.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$pct%'),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
