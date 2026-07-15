import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/island_decorations.dart';
import '../../providers/app_audio_provider.dart';
import '../../providers/app_providers.dart';
import 'widgets/more_subpage_header.dart';

class AudioSettingsPage extends ConsumerWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final settingsAsync = ref.watch(appAudioSettingsProvider);
    final settings = settingsAsync.valueOrNull;
    final notifier = ref.read(appAudioSettingsProvider.notifier);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoreSubpageHeader(title: '声音设置'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    IslandGlassCard(
                      palette: palette,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.graphic_eq_rounded,
                                  color: palette.primary),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '岛屿音乐与操作音效',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '在岛屿、我的世界、今日日常等沉浸页面播放',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (settings == null)
                            const LinearProgressIndicator(minHeight: 2)
                          else ...[
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: settings.bgmEnabled,
                              title: const Text('背景音乐'),
                              subtitle: const Text('按本地时间自动切换白天 / 夜晚音乐'),
                              activeThumbColor: palette.accent,
                              activeTrackColor:
                                  palette.accent.withValues(alpha: 0.28),
                              onChanged: notifier.setBgmEnabled,
                            ),
                            _AudioVolumeSlider(
                              label: '背景音乐音量',
                              value: settings.bgmVolume,
                              enabled: settings.bgmEnabled,
                              accent: palette.accent,
                              onChanged: notifier.setBgmVolume,
                            ),
                            const Divider(height: 22),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: settings.sfxEnabled,
                              title: const Text('操作音效'),
                              subtitle: const Text('主要按钮、待办完成、成长奖励和 VIP 成功'),
                              activeThumbColor: palette.accent,
                              activeTrackColor:
                                  palette.accent.withValues(alpha: 0.28),
                              onChanged: notifier.setSfxEnabled,
                            ),
                            _AudioVolumeSlider(
                              label: '操作音效音量',
                              value: settings.sfxVolume,
                              enabled: settings.sfxEnabled,
                              accent: palette.accent,
                              onChanged: notifier.setSfxVolume,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioVolumeSlider extends StatelessWidget {
  const _AudioVolumeSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$percent%'),
            ],
          ),
          Slider(
            value: value,
            activeColor: accent,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
