import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/daily_level_unlock_prompt.dart';
import '../../core/growth/growth_system.dart';
import '../../core/growth/today_mood_display.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/adaptive_viewport.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/growth_progress_panel.dart';
import 'landing_warm_quote_box.dart';
import 'landing_welcome_section.dart';
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

  /// 预览容器相对原尺寸的倍数（扩大 0.8 倍 ≈ 1.8× 视觉面积）。
  static const _previewScale = 2.12;

  /// 相机缩放：Landing 预览专用（岛面基准放大后略降 zoom，避免预览框裁切）。
  static const _islandZoomBoost = 3.45;
  bool _dailyUnlockPromptChecked = false;
  final ScrollController _cardScrollCtrl = ScrollController();
  bool _cardScrollable = false;

  void _syncCardScrollable() {
    if (!_cardScrollCtrl.hasClients) return;
    final scrollable = _cardScrollCtrl.position.maxScrollExtent > 0.5;
    if (scrollable != _cardScrollable && mounted) {
      setState(() => _cardScrollable = scrollable);
    }
  }

  @override
  void initState() {
    super.initState();
    _cardScrollCtrl.addListener(_syncCardScrollable);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCardScrollable());
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
  void dispose() {
    _cardScrollCtrl.removeListener(_syncCardScrollable);
    _cardScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final growthAsync = ref.watch(growthSummaryProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final moodId = resolveTodayLandingMoodId(profile: profile);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ref.listen<AsyncValue<GrowthSummary>>(growthSummaryProvider, (prev, next) {
      next.whenData((data) {
        if (_dailyUnlockPromptChecked || data.isGuest) return;
        _dailyUnlockPromptChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await maybeShowDailyLevelUnlockPrompt(context, ref, summary: data);
        });
      });
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncCardScrollable());
    });

    return Scaffold(
      backgroundColor: palette.gradientEnd,
      body: IslandScaffold(
        palette: palette,
        showOrbs: false,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewW = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : PhoneViewportDesign.designSize.width;
              final contentW = viewW - AppLayout.pageHorizontal * 2;
              final targetW = _previewBaseW * _previewScale;
              final targetH = _previewBaseH * _previewScale;
              final islandW = math.min(contentW, targetW);
              final widthCompensation =
                  islandW >= targetW - 1 ? 1.0 : targetW / islandW;
              final previewZoom = _islandZoomBoost * widthCompensation;
              final islandH = targetH;
              final availableH = constraints.maxHeight;
              const bottomControlsH = 44.0 + 28.0 + 10.0 + 20.0 + 12.0;
              const minCardContentH = 248.0;
              const verticalGaps = 12.0 + 12.0 + 20.0;
              final maxIslandH =
                  availableH - bottomControlsH - minCardContentH - verticalGaps;
              final adaptiveIslandH = maxIslandH.isFinite
                  ? math.min(islandH, math.max(88.0, maxIslandH))
                  : islandH;
              final islandScaleFactor = adaptiveIslandH / islandH;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  AppLayout.pageHorizontal,
                  12,
                  AppLayout.pageHorizontal,
                  12 + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        height: adaptiveIslandH,
                        width: islandW,
                        child: GrowthWorldViewport(
                          moodId: moodId,
                          summary: summary,
                          compact: true,
                          previewZoom: previewZoom * islandScaleFactor,
                          interactive: false,
                          enginePaused: false,
                          force2D: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, _) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _syncCardScrollable(),
                          );
                          return IslandGlassCard(
                            palette: palette,
                            padding: const EdgeInsets.fromLTRB(16, 18, 8, 16),
                            child: Scrollbar(
                              controller: _cardScrollCtrl,
                              thumbVisibility: _cardScrollable,
                              trackVisibility: _cardScrollable,
                              radius: const Radius.circular(6),
                              thickness: 4,
                              interactive: true,
                              child: SingleChildScrollView(
                                controller: _cardScrollCtrl,
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GrowthProgressPanel(
                                      summary: summary,
                                      displayMoodId: moodId,
                                    ),
                                    const SizedBox(height: 16),
                                    const LandingWelcomeSection(),
                                    const SizedBox(height: 16),
                                    const LandingWarmQuoteBox(),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    IslandPrimaryAction(
                      label: '点亮今天的小岛',
                      palette: palette,
                      height: 44,
                      onPressed: _onPrimary,
                    ),
                    const SizedBox(height: 28),
                    TextButton(
                      onPressed: _onSwitchAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8C7B6B),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        '登录其他账号？',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
