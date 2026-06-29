import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../core/l10n/l10n_extension.dart';
import '../providers/main_shell_tab_provider.dart';
import '../features/auth/auth_page.dart';

import '../features/auth/register_page.dart';

import '../features/island/island_home_page.dart';

import '../features/island/growth_island_visual_debug_page.dart';

import '../features/more/more_page.dart';

import '../features/more/companion_showcase_page.dart';
import '../features/more/app_about_page.dart';
import '../features/more/my_level_page.dart';
import '../features/more/reminder_settings_page.dart';

import '../features/onboarding/companion_page.dart';

import '../features/onboarding/gender_page.dart';

import '../features/onboarding/time_travel_page.dart';

import '../features/onboarding/welcome_page.dart';

import '../features/records/record_page.dart';

import '../features/status/mood_status_page.dart';

import '../features/today/add_moment_flow.dart';

import '../features/today/daily_entry_flow.dart';

import '../core/constants/companion_roles.dart';
import '../providers/app_providers.dart';

import '../providers/auth_provider.dart' show AuthState, authProvider;

final _rootKey = GlobalKey<NavigatorState>();

bool _isMainTab(String path) =>
    path == '/island' ||
    path == '/records' ||
    path == '/insights' ||
    path == '/more' ||
    path == '/today' ||
    path == '/status';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

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
  });

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      if (!auth.ready) return null;

      final path = state.matchedLocation;

      final loggedIn = auth.isLoggedIn;

      final debugPublic = kDebugMode && path.startsWith('/debug/');

      final public = path == '/welcome' ||
          path == '/auth' ||
          path == '/auth/register' ||
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

      if (loggedIn &&
          (path == '/welcome' || path == '/auth' || path == '/auth/register')) {
        final profile = ref.read(profileProvider).valueOrNull;

        if (profile == null) return null;

        return '/island';
      }

      if (loggedIn && path == '/onboarding/gender') {
        final profile = ref.read(profileProvider).valueOrNull;

        if (profile != null && profile.hasCompanionRole) return '/island';
      }

      if (loggedIn && mainTab) {
        final profile = ref.read(profileProvider).valueOrNull;

        if (profile == null) return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
          path: '/onboarding/gender', builder: (_, __) => const GenderPage()),
      GoRoute(
          path: '/onboarding/companion',
          builder: (_, __) => const CompanionPage()),
      GoRoute(
        path: '/onboarding/arrival',
        builder: (context, state) {
          final mood = state.uri.queryParameters['mood'] ?? 'calm';

          return TimeTravelArrivalPage(moodId: mood);
        },
      ),
      GoRoute(
        path: '/more/my-level',
        builder: (context, state) {
          final scrollTo = state.uri.queryParameters['scrollTo'];
          return MyLevelPage(scrollToSection: scrollTo);
        },
      ),
      GoRoute(
        path: '/more/reminders',
        builder: (_, __) => const ReminderSettingsPage(),
      ),
      GoRoute(
        path: '/more/companion',
        builder: (_, __) => const CompanionShowcasePage(),
      ),
      GoRoute(
        path: '/more/about',
        builder: (_, __) => const AppAboutPage(),
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
  );
});

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell>
    with WidgetsBindingObserver {
  Future<void> runDailyEntry() {
    if (!mounted) return Future.value();
    return runDailyEntryFlowIfNeeded(context, ref);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => runDailyEntry());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => runDailyEntry());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      final prevId = previous?.valueOrNull?.userId;
      final nextId = next.valueOrNull?.userId;
      if (nextId != null && nextId != prevId) {
        WidgetsBinding.instance.addPostFrameCallback((_) => runDailyEntry());
      }
    });

    final tabIndex = widget.navigationShell.currentIndex;
    if (ref.read(mainShellTabIndexProvider) != tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(mainShellTabIndexProvider.notifier).state = tabIndex;
        }
      });
    }

    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: _FloatingMainNavigationBar(
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
          ref.read(mainShellTabIndexProvider.notifier).state = index;
          widget.navigationShell.goBranch(index);
        },
        onAddPressed: () => showAddMomentFlow(context, ref),
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
    required this.selectedIndex,
    required this.items,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int selectedIndex;
  final List<_MainNavigationItem> items;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
      child: SizedBox(
        height: 82,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      _BottomTabButton(
                        item: items[0],
                        selected: selectedIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                      _BottomTabButton(
                        item: items[1],
                        selected: selectedIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                      const SizedBox(width: 76),
                      _BottomTabButton(
                        item: items[2],
                        selected: selectedIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                      _BottomTabButton(
                        item: items[3],
                        selected: selectedIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              child: _AddMomentButton(onPressed: onAddPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MainNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = Theme.of(context).colorScheme.primary;
    final inactive = Colors.black.withValues(alpha: 0.42);
    final color = selected ? active : inactive;
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

class _AddMomentButton extends StatelessWidget {
  const _AddMomentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF7A66), Color(0xFFFF4E4E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5A52).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}
