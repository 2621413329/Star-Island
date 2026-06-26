import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/constants/emotion_catalog.dart';
import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/adaptive_viewport.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/growth_progress_panel.dart';
import 'landing_warm_quote_box.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  /// 原先 Landing 预览框基准尺寸（宽 × 高）。
  static const _previewBaseW = 257.0;
  static const _previewBaseH = 134.0;
  /// 预览容器相对原尺寸的倍数（略小于岛屿页，避免引导页过高需滚动）。
  static const _previewScale = 1.18;
  /// 相机缩放：Landing 预览专用。
  static const _islandZoomBoost = 2.35;
  bool _dailyUnlockPromptChecked = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        ref.read(profileProvider.notifier).refresh();
        ref.invalidate(growthSummaryProvider);
      }
    });
  }

  void _onPrimary() {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      context.go('/auth');
      return;
    }
    context.go('/island');
  }

  Future<void> _onSwitchAccount() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final growthAsync = ref.watch(growthSummaryProvider);
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final moodId = summary.todayMood ?? defaultEmotionId;

    ref.listen<AsyncValue<GrowthSummary>>(growthSummaryProvider, (prev, next) {
      next.whenData((data) {
        if (_dailyUnlockPromptChecked || data.isGuest) return;
        _dailyUnlockPromptChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await maybeShowDailyLevelUnlockPrompt(context, ref, summary: data);
        });
      });
    });

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        showOrbs: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : PhoneViewportDesign.designSize.width;
              final contentW = viewW - AppLayout.pageHorizontal * 2;
              final targetW = _previewBaseW * _previewScale;
              final targetH = _previewBaseH * _previewScale;
              final islandW = math.min(contentW, targetW);
              // 屏宽不足时补 zoom；与 _islandZoomBoost 叠加使岛屿视觉面积约为原先 2 倍
              final widthCompensation =
                  islandW >= targetW - 1 ? 1.0 : targetW / islandW;
              final previewZoom = _islandZoomBoost * widthCompensation;
              final islandH = targetH;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.pageHorizontal,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: constraints.maxHeight > 600 ? 24 : 8),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: islandH,
                              width: islandW,
                              child: GrowthWorldViewport(
                                moodId: moodId,
                                summary: summary,
                                compact: true,
                                previewZoom: previewZoom,
                                interactive: false,
                                enginePaused: false,
                                force2D: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            IslandGlassCard(
                              palette: palette,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GrowthProgressPanel(summary: summary),
                                  const SizedBox(height: 14),
                                  const LandingWarmQuoteBox(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      IslandPrimaryAction(
                        label: '点亮今天的小岛',
                        palette: palette,
                        height: 44,
                        onPressed: _onPrimary,
                      ),
                      TextButton(
                        onPressed: _onSwitchAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8C7B6B),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          '登录其他账号？',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
