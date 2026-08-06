import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_fonts.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/force_update_provider.dart';

/// iOS 强制更新页：不可返回，仅可跳转 App Store。
class ForceUpdatePage extends ConsumerWidget {
  const ForceUpdatePage({super.key});

  static const _fallbackStoreUrl = 'https://apps.apple.com/app/id6782086773';

  Future<void> _openStore(BuildContext context, String storeUrl) async {
    final uri = Uri.tryParse(storeUrl) ?? Uri.parse(_fallbackStoreUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppFeedback.showWeak(context, '无法打开 App Store，请手动搜索「星屿」更新');
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showWeak(context, '无法打开 App Store，请手动搜索「星屿」更新');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);
    final state = ref.watch(forceUpdateProvider).valueOrNull;
    final policy = state?.policy;
    final title = policy?.title ?? '需要更新后才能继续使用';
    final message = policy?.message ??
        '当前版本已停止支持，请前往 App Store 更新至最新版本。';
    final storeUrl = policy?.storeUrl ?? _fallbackStoreUrl;
    final local = state?.localVersion;
    final latest = policy?.latestVersion;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IslandScaffold(
          palette: palette,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.system_update_alt_rounded,
                    size: 56,
                    color: palette.accent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: appTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D3229),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: appTextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: palette.primary.withValues(alpha: 0.72),
                    ),
                  ),
                  if (local != null || latest != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      [
                        if (local != null) '当前版本：$local',
                        if (latest != null) '最新版本：$latest',
                      ].join('\n'),
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: palette.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IslandPrimaryAction(
                    label: '前往 App Store 更新',
                    palette: palette,
                    onPressed: () => _openStore(context, storeUrl),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
