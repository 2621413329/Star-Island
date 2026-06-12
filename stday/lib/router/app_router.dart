import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../features/auth/auth_page.dart';

import '../features/auth/register_page.dart';

import '../features/island/island_home_page.dart';

import '../features/island/growth_island_visual_debug_page.dart';

import '../features/more/more_page.dart';

import '../features/more/companion_showcase_page.dart';
import '../features/more/app_about_page.dart';
import '../features/more/my_level_page.dart';

import '../features/onboarding/companion_page.dart';

import '../features/onboarding/gender_page.dart';

import '../features/onboarding/time_travel_page.dart';

import '../features/onboarding/welcome_page.dart';

import '../features/records/record_page.dart';

import '../features/status/mood_status_page.dart';

import '../features/today/daily_entry_flow.dart';

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

        if (profile.gender == null) return '/onboarding/gender';

        return '/island';
      }

      if (loggedIn && mainTab) {
        final profile = ref.read(profileProvider).valueOrNull;

        if (profile == null) return null;

        if (profile.gender == null) return '/onboarding/gender';
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
      GoRoute(path: '/more/my-level', builder: (_, __) => const MyLevelPage()),
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

class _MainShellState extends ConsumerState<_MainShell> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      runDailyEntryFlowIfNeeded(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            label: '我的岛屿',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '今日记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            label: '成长洞察',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: '更多'),
        ],
      ),
    );
  }
}
