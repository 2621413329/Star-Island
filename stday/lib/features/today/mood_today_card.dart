import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/mood_face_painter.dart';
import '../../design_system/mood_face_selector.dart';
import '../../providers/app_providers.dart';

class MoodTodayCard extends ConsumerWidget {
  const MoodTodayCard({super.key, required this.palette});

  final MoodPalette palette;

  Future<void> _editMood(BuildContext context, WidgetRef ref) async {
    final current = ref.read(profileProvider).valueOrNull?.todayMood;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('编辑今日心情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              MoodFaceSelector(
                selectedId: current,
                onSelected: (id) async {
                  await ref.read(profileProvider.notifier).updateMood(id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodId = ref.watch(profileProvider).valueOrNull?.todayMood;
    final mood = moodId != null ? moodById(moodId) : null;
    final time = DateFormat('今天, M月d日, HH:mm', 'zh_CN').format(DateTime.now());

    return GestureDetector(
      onTap: () => _editMood(context, ref),
      child: IslandGlassCard(
        palette: palette,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            if (mood != null)
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: mood.color, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: mood.color.withValues(alpha: 0.25), blurRadius: 10),
                  ],
                ),
                child: CustomPaint(
                  painter: MoodFacePainter(type: mood.faceType, color: mood.color),
                ),
              ),
            if (mood != null) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW ARE YOU?',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: mood.color.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      mood.label,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: mood.color),
                    ),
                    Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6B))),
                  ],
                ),
              ),
            ] else
              const Expanded(child: Text('点选卡片设置今日心情')),
            Icon(Icons.edit_rounded, color: palette.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
