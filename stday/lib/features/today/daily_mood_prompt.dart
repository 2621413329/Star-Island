import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/mood_face_selector.dart';
import '../../providers/app_providers.dart';

/// 每日心情选择弹窗；返回选中的心情 id，取消则返回 null。
Future<String?> showDailyMoodPicker(BuildContext context, WidgetRef ref) async {
  final palette = ref.read(moodPaletteProvider);
  final current = ref.read(profileProvider).valueOrNull?.todayMood;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '今天的心情是？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '选好后记录今日日常，小岛会随之变化',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF8C7B6B), height: 1.4),
              ),
              const SizedBox(height: 22),
              MoodFaceSelector(
                selectedId: current,
                size: 56,
                gender: ref.read(profileProvider).valueOrNull?.gender,
                onSelected: (id) => Navigator.pop(ctx, id),
              ),
            ],
          ),
        ),
      );
    },
  );
}
