import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/mood_theme.dart';
import '../../design_system/island_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_profile_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const palette = defaultPalette;
    final profile = ref.watch(teacherProfileProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text('更多', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        profile.when(
          loading: () => IslandGlassCard(
            palette: palette,
            child: const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (p) => IslandGlassCard(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('昵称：${p.nickname}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('登录名：${p.username}', style: const TextStyle(color: Color(0xFF8C7B6B))),
                const SizedBox(height: 6),
                Text('负责班级：${p.className}', style: const TextStyle(color: Color(0xFF8C7B6B))),
                const SizedBox(height: 4),
                const Text(
                  '仅可查看本班学生的心情与预警',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8C7B6B)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        IslandGlassCard(
          palette: palette,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('数据说明', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text(
                '教师端仅展示脱敏后的统计与风险标签，不包含学生备注原文。信息仅供关怀参考，请妥善使用。',
                style: TextStyle(height: 1.45, color: Color(0xFF8C7B6B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IslandGlassCard(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('成长伙伴 · 教师端', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('版本 1.0.0', style: TextStyle(color: Colors.brown.shade300, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        IslandPrimaryAction(
          label: '退出登录',
          palette: palette,
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}
