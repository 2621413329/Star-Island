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
      backgroundColor: const Color(0xFFE8F4F8),
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: Material(
        color: Colors.transparent,
        elevation: 0,
        child: _FloatingMainNavigationBar(
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
              bottom: 22,
              child: _AddMomentButton(onPressed: onAddPressed),
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
    return Semantics(
      button: true,
      label: '快速记录今日日常',
      child: GestureDetector(
        onTap: onPressed,
        child: const SizedBox(
          width: 62,
          height: 62,
          child: CustomPaint(
            painter: _AddMomentButtonPainter(),
          ),
        ),
      ),
    );
  }
}

class _AddMomentButtonPainter extends CustomPainter {
  const _AddMomentButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    canvas.drawCircle(
      center + const Offset(0, 7),
      radius * 0.88,
      Paint()
        ..color = const Color(0xFFFF5A52).withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF806C), Color(0xFFFF454D)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    final half = radius * 0.40;
    canvas.drawLine(
      Offset(center.dx - half, center.dy),
      Offset(center.dx + half, center.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - half),
      Offset(center.dx, center.dy + half),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AddMomentButtonPainter oldDelegate) => false;
}
