import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../core/l10n/l10n_extension.dart';
import '../core/audio/app_audio_assets.dart';
import '../core/theme/mood_theme.dart';
import '../providers/app_audio_provider.dart';
import '../providers/app_providers.dart';
import '../providers/main_shell_tab_provider.dart';
import '../providers/story_day_provider.dart';
import '../features/auth/auth_page.dart';

import '../features/auth/register_page.dart';

import '../features/island/island_home_page.dart';

import '../features/island/growth_island_visual_debug_page.dart';

import '../features/more/more_page.dart';

import '../features/more/audio_settings_page.dart';
import '../features/more/companion_showcase_page.dart';
import '../features/more/app_about_page.dart';
import '../features/more/my_level_page.dart';
import '../features/more/reminder_settings_page.dart';
import '../features/membership/membership_page.dart';
import '../features/legal/legal_document_page.dart';
import '../features/update/force_update_page.dart';
import '../core/legal/legal_documents.dart';
import '../providers/force_update_provider.dart';

import '../features/onboarding/companion_page.dart';

import '../features/onboarding/gender_page.dart';

import '../features/onboarding/time_travel_page.dart';

import '../features/onboarding/welcome_page.dart';

import '../features/records/record_page.dart';

import '../features/status/mood_status_page.dart';

import '../design_system/healing_jelly_button.dart';
import '../design_system/app_feedback.dart';

import '../features/today/add_moment_flow.dart';

import '../features/today/daily_entry_flow.dart';

import '../core/constants/companion_roles.dart';

import '../providers/auth_provider.dart' show AuthState, authProvider;

final _rootKey = GlobalKey<NavigatorState>();

bool _isMainTab(String path) =>
    path == '/island' ||
    path == '/records' ||
    path == '/insights' ||
    path == '/more' ||
    path == '/today' ||
    path == '/status';

/// 触发 GoRouter redirect 重算，但不重建路由实例（避免主壳/岛屿页被重复挂载）。
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isLoggedIn == true && !next.isLoggedIn) {
      ref.invalidate(profileProvider);
      ref.invalidate(todayMomentsProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _rootKey.currentContext;

        if (ctx != null && ctx.mounted) {
          GoRouter.of(ctx).go('/auth');
        }
      });
    }

    if (next.isLoggedIn && previous?.isLoggedIn != true) {
      ref.read(profileProvider.notifier).refresh();
    }
    refresh.ping();
  });

  ref.listen(profileProvider, (_, __) => refresh.ping());
  ref.listen(forceUpdateProvider, (_, __) => refresh.ping());

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final profileAsync = ref.read(profileProvider);
      final forceUpdate = ref.read(forceUpdateProvider);

      if (!auth.ready) return null;

      final path = state.matchedLocation;

      // iOS 强制更新：拦截所有页面（检查未完成前不拦截）。
      if (forceUpdate.hasValue && (forceUpdate.valueOrNull?.required ?? false)) {
        if (path != '/force-update') return '/force-update';
        return null;
      }
      if (path == '/force-update') {
        return '/welcome';
      }

      // Widget / 外部 deep link：勿交给 GoRouter 解析 stday://，统一落岛页由 WidgetDeepLinkHost 消费。
      if (state.uri.scheme == 'stday') {
        if (!auth.isLoggedIn) return '/auth';
        return '/island';
      }

      final loggedIn = auth.isLoggedIn;
      final profile = profileAsync.valueOrNull;
      final profileLoadFailed = profileAsync.hasError;

      final debugPublic = kDebugMode && path.startsWith('/debug/');

      final public = path == '/welcome' ||
          path == '/auth' ||
          path == '/auth/register' ||
          path == '/legal/terms' ||
          path == '/legal/privacy' ||
          debugPublic;

      final onboardingPath = path.startsWith('/onboarding/');

      final mainTab = _isMainTab(path);

      if (path == '/today') return '/records';

      if (path == '/status') return '/insights';

      if (!loggedIn) {
        if (onboardingPath || mainTab || path.startsWith('/more/')) {
          return '/auth';
        }

        if (!public) return '/welcome';
      }

      if (loggedIn && profileLoadFailed) {
        if (mainTab || onboardingPath || path.startsWith('/more/')) {
          return '/welcome';
        }
        return null;
      }

      if (loggedIn &&
          (path == '/welcome' || path == '/auth' || path == '/auth/register')) {
        if (profile == null) return null;

        return profile.hasCompanionRole ? '/island' : '/onboarding/gender';
      }

      if (loggedIn && path == '/onboarding/gender') {
        if (profile != null && profile.hasCompanionRole) return '/island';
      }

      if (loggedIn &&
          onboardingPath &&
          path != '/onboarding/gender' &&
          profile != null &&
          !profile.hasCompanionRole) {
        return '/onboarding/gender';
      }

      if (loggedIn && !onboardingPath) {
        if (profile == null) return path == '/welcome' ? null : '/welcome';
        if (!profile.hasCompanionRole) return '/onboarding/gender';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/force-update',
        builder: (_, __) => const ForceUpdatePage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.welcome,
          audioKey: state.uri.toString(),
          child: const WelcomePage(),
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.welcome,
          audioKey: state.uri.toString(),
          child: const AuthPage(),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.welcome,
          audioKey: state.uri.toString(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding/gender',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.welcome,
          audioKey: state.uri.toString(),
          child: const GenderPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding/companion',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.welcome,
          audioKey: state.uri.toString(),
          child: const CompanionPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding/arrival',
        builder: (context, state) {
          final mood = state.uri.queryParameters['mood'] ?? 'calm';

          return _AudioRouteHost(
            context: AppBgmContext.welcome,
            audioKey: state.uri.toString(),
            child: TimeTravelArrivalPage(moodId: mood),
          );
        },
      ),
      GoRoute(
        path: '/more/my-level',
        builder: (context, state) {
          final scrollTo = state.uri.queryParameters['scrollTo'];
          return _AudioRouteHost(
            context: AppBgmContext.more,
            audioKey: state.uri.toString(),
            child: MyLevelPage(scrollToSection: scrollTo),
          );
        },
      ),
      GoRoute(
        path: '/more/reminders',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const ReminderSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/more/audio',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const AudioSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/more/companion',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const CompanionShowcasePage(),
        ),
      ),
      GoRoute(
        path: '/more/membership',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const MembershipPage(),
        ),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const LegalDocumentPage(document: userAgreement),
        ),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const LegalDocumentPage(document: privacyPolicy),
        ),
      ),
      GoRoute(
        path: '/more/about',
        builder: (_, state) => _AudioRouteHost(
          context: AppBgmContext.more,
          audioKey: state.uri.toString(),
          child: const AppAboutPage(),
        ),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/growth-island',
          builder: (_, __) => const GrowthIslandVisualDebugPage(),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/island', builder: (_, __) => const IslandHomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/records', builder: (_, __) => const RecordPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/insights',
                  builder: (_, __) => const MoodStatusPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/more', builder: (_, __) => const MorePage()),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      if (state.uri.scheme == 'stday') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) GoRouter.of(context).go('/island');
        });
        return const SizedBox.shrink();
      }
      return Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      );
    },
  );
});

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _AudioRouteHost extends ConsumerStatefulWidget {
  const _AudioRouteHost({
    required this.context,
    required this.audioKey,
    required this.child,
  });

  final AppBgmContext context;
  final String audioKey;
  final Widget child;

  @override
  ConsumerState<_AudioRouteHost> createState() => _AudioRouteHostState();
}

class _AudioRouteHostState extends ConsumerState<_AudioRouteHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAudio());
  }

  @override
  void didUpdateWidget(covariant _AudioRouteHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context != widget.context ||
        oldWidget.audioKey != widget.audioKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAudio());
    }
  }

  void _syncAudio() {
    if (!mounted) return;
    unawaited(
      ref.read(appAudioControllerProvider).setBgmContext(
            widget.context,
            key: 'route-${widget.audioKey}',
          ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MainShellState extends ConsumerState<_MainShell>
    with WidgetsBindingObserver {
  bool _dailyEntryScheduled = false;

  AppBgmContext? get _currentBgmContext {
    return switch (widget.navigationShell.currentIndex) {
      0 || 1 => AppBgmContext.island,
      2 => AppBgmContext.insights,
      3 => AppBgmContext.more,
      _ => null,
    };
  }

  Future<void> runDailyEntry() {
    if (!mounted) return Future.value();
    return runDailyEntryFlowIfNeeded(context, ref);
  }

  void _scheduleDailyEntry() {
    if (_dailyEntryScheduled) return;
    _dailyEntryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        await runDailyEntry();
      } finally {
        _dailyEntryScheduled = false;
      }
    });
  }

  void _syncImmersiveAudio() {
    final context = _currentBgmContext;
    unawaited(
      ref.read(appAudioControllerProvider).setBgmContext(
            context,
            key: 'main-${context?.name ?? 'none'}',
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDailyEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapImmersiveAudio());
  }

  Future<void> _bootstrapImmersiveAudio() async {
    if (!mounted) return;
    _syncImmersiveAudio();
    try {
      final settings = await ref.read(appAudioSettingsProvider.future);
      if (!mounted) return;
      await ref.read(appAudioControllerProvider).updateSettings(settings);
      if (!mounted) return;
      _syncImmersiveAudio();
    } catch (e, st) {
      debugPrint('Main shell audio bootstrap skipped: $e\n$st');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      ref.read(appAudioControllerProvider).setBgmContext(
            null,
            key: 'main-shell-disposed',
          ),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(ref.read(appAudioControllerProvider).handleLifecycle(state));
    if (state == AppLifecycleState.resumed) {
      _scheduleDailyEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      final prevId = previous?.valueOrNull?.userId;
      final nextId = next.valueOrNull?.userId;
      if (nextId != null && nextId != prevId) {
        _scheduleDailyEntry();
      }
    });
    ref.watch(appAudioSettingsProvider);
    ref.listen(appAudioSettingsProvider, (previous, next) {
      next.whenData((settings) {
        unawaited(
          ref.read(appAudioControllerProvider).updateSettings(settings),
        );
        _syncImmersiveAudio();
      });
    });

    final tabIndex = widget.navigationShell.currentIndex;
    final palette = ref.watch(moodPaletteProvider);
    if (ref.read(mainShellTabIndexProvider) != tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(mainShellTabIndexProvider.notifier).state = tabIndex;
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncImmersiveAudio();
    });

    return Scaffold(
      backgroundColor: palette.gradientStart,
      body: widget.navigationShell,
      extendBody: false,
      bottomNavigationBar: Material(
        color: Colors.transparent,
        elevation: 0,
        child: _FloatingMainNavigationBar(
          palette: palette,
          selectedIndex: tabIndex,
          items: [
            _MainNavigationItem(
              icon: Icons.landscape_outlined,
              label: context.l10n.tabIsland,
            ),
            _MainNavigationItem(
              icon: Icons.menu_book_outlined,
              label: context.l10n.tabToday,
            ),
            _MainNavigationItem(
              icon: Icons.spa_outlined,
              label: context.l10n.tabGrowth,
            ),
            _MainNavigationItem(
              icon: Icons.menu,
              label: context.l10n.tabMore,
            ),
          ],
          onTabSelected: (index) {
            unawaited(
              ref.read(appAudioControllerProvider).playSfx(AppSfx.tap),
            );
            ref.read(mainShellTabIndexProvider.notifier).state = index;
            widget.navigationShell.goBranch(index);
          },
          onAddPressed: () {
            unawaited(
              ref.read(appAudioControllerProvider).playSfx(AppSfx.tap),
            );
            final selectedStoryDay = ref.read(selectedStoryDayProvider);
            if (tabIndex == 1 && !isCalendarToday(selectedStoryDay)) {
              AppFeedback.showWeak(
                context,
                '当前是记录今天的日常哦，如需补充日常，请点击页面小字「补充一个日常」',
              );
              return;
            }
            showAddMomentFlow(context, ref);
          },
        ),
      ),
    );
  }
}

class _MainNavigationItem {
  const _MainNavigationItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _FloatingMainNavigationBar extends StatelessWidget {
  const _FloatingMainNavigationBar({
    required this.palette,
    required this.selectedIndex,
    required this.items,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final MoodPalette palette;
  final int selectedIndex;
  final List<_MainNavigationItem> items;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: SizedBox(
        height: 70,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: const _BottomNavBackgroundPainter(),
                  child: Row(
                    children: [
                      _BottomTabButton(
                        item: items[0],
                        selected: selectedIndex == 0,
                        accent: palette.accent,
                        onTap: () => onTabSelected(0),
                      ),
                      _BottomTabButton(
                        item: items[1],
                        selected: selectedIndex == 1,
                        accent: palette.accent,
                        onTap: () => onTabSelected(1),
                      ),
                      const SizedBox(width: 76),
                      _BottomTabButton(
                        item: items[2],
                        selected: selectedIndex == 2,
                        accent: palette.accent,
                        onTap: () => onTabSelected(2),
                      ),
                      _BottomTabButton(
                        item: items[3],
                        selected: selectedIndex == 3,
                        accent: palette.accent,
                        onTap: () => onTabSelected(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 22,
              child: HealingJellyIconButton(
                onPressed: onAddPressed,
                icon: Icons.add_rounded,
                tone: HealingJellyTone.fromPalette(palette),
                size: 62,
                iconSize: 30,
                semanticLabel: '快速记录今日日常',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBackgroundPainter extends CustomPainter {
  const _BottomNavBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(24, 0)
      ..lineTo(size.width / 2 - 48, 0)
      ..cubicTo(
        size.width / 2 - 34,
        0,
        size.width / 2 - 34,
        20,
        size.width / 2,
        20,
      )
      ..cubicTo(
        size.width / 2 + 34,
        20,
        size.width / 2 + 34,
        0,
        size.width / 2 + 48,
        0,
      )
      ..lineTo(size.width - 24, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 24)
      ..lineTo(size.width, size.height - 24)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - 24,
        size.height,
      )
      ..lineTo(24, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 24)
      ..lineTo(0, 24)
      ..quadraticBezierTo(0, 0, 24, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.97),
    );
  }

  @override
  bool shouldRepaint(covariant _BottomNavBackgroundPainter oldDelegate) =>
      false;
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _MainNavigationItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.black.withValues(alpha: 0.42);
    final color = selected ? accent : inactive;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  scale: selected ? 1.08 : 1,
                  child: Icon(item.icon, color: color, size: 24),
                ),
                const SizedBox(height: 3),
                Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
