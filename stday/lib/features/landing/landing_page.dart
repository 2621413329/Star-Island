import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/growth/growth_system.dart';
import '../../core/layout/app_layout.dart';
import '../../core/theme/mood_theme.dart';
import '../../design_system/growth_island_rules_sheet.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/adaptive_viewport.dart';
import '../../island/providers/growth_summary_provider.dart';
import '../../island/viewport/growth_world_viewport.dart';
import '../../island/widgets/growth_progress_panel.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import 'landing_growth_provider.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showGrowthIslandRulesIfNeeded(context);
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
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null || profile.gender == null) {
      context.go('/onboarding/gender');
      return;
    }
    context.go('/island');
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final growthAsync = ref.watch(growthSummaryProvider);
    final summary = growthAsync.valueOrNull ?? GrowthSummary.guest();
    final moodId = summary.todayMood ?? 'calm';

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
              final islandW = (viewW * 0.66).clamp(188.0, 268.0);
              final islandH = (islandW * 0.52).clamp(120.0, 150.0);

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
                                interactive: false,
                                enginePaused: false,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GrowthProgressPanel(summary: summary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _LandingPrivacyHint(),
                      const SizedBox(height: 10),
                      IslandPrimaryAction(
                        label: '点亮今天的小岛',
                        palette: palette,
                        height: 44,
                        onPressed: _onPrimary,
                      ),
                      TextButton(
                        onPressed: () => context.push('/auth'),
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

class _LandingPrivacyHint extends StatelessWidget {
  const _LandingPrivacyHint();

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        '🔒 安心记录\n你的日常记录主要由自己保存。\n老师查看的是成长趋势与需要帮助的提醒。',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          color: palette.primary.withValues(alpha: 0.42),
        ),
      ),
    );
  }
}
