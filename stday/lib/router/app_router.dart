import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_page.dart';
import '../features/more/more_page.dart';
import '../features/onboarding/companion_page.dart';
import '../features/onboarding/gender_page.dart';
import '../features/onboarding/time_travel_page.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/status/today_status_page.dart';
import '../features/today/today_stories_page.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart' show AuthState, authProvider;

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isLoggedIn && previous?.isLoggedIn != true) {
      ref.read(profileProvider.notifier).refresh();
    }
  });

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final loggedIn = auth.isLoggedIn;
      final public = path == '/welcome' || path == '/auth';

      if (!loggedIn && !public) return '/welcome';
      if (loggedIn && (path == '/welcome' || path == '/auth')) {
        final profile = ref.read(profileProvider).valueOrNull;
        if (profile == null) return null;
        if (profile.gender == null) return '/onboarding/gender';
        if (profile.companionStyle == null || !profile.onboardingCompleted) {
          return '/onboarding/companion';
        }
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
      GoRoute(path: '/onboarding/gender', builder: (_, __) => const GenderPage()),
      GoRoute(path: '/onboarding/companion', builder: (_, __) => const CompanionPage()),
      GoRoute(
        path: '/onboarding/arrival',
        builder: (context, state) {
          final mood = state.uri.queryParameters['mood'] ?? 'calm';
          return TimeTravelArrivalPage(moodId: mood);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/today', builder: (_, __) => const TodayStoriesPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/status', builder: (_, __) => const TodayStatusPage()),
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

class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '今日故事'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), label: '今日状态'),
          NavigationDestination(icon: Icon(Icons.menu), label: '更多'),
        ],
      ),
    );
  }
}
