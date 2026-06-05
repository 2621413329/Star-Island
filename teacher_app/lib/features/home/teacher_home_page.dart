import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mood_theme.dart';
import '../../design_system/island_ui.dart';
import '../../providers/growth_providers.dart';
import '../growth_focus/growth_focus_page.dart';
import '../mood/mood_list_page.dart';
import '../settings/settings_page.dart';

class TeacherHomePage extends ConsumerStatefulWidget {
  const TeacherHomePage({super.key});

  @override
  ConsumerState<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<TeacherHomePage> {
  int _index = 0;

  static const _growthFocusTabIndex = 1;

  static const _tabs = [
    (icon: Icons.favorite_rounded, label: '心情'),
    (icon: Icons.eco_rounded, label: '成长关注'),
    (icon: Icons.more_horiz_rounded, label: '更多'),
  ];

  Widget _tabIcon(IconData icon, {required int badgeCount}) {
    final base = Icon(icon);
    if (badgeCount <= 0) return base;
    final label = badgeCount > 99 ? '99+' : '$badgeCount';
    return Badge(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFFE53935),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      offset: const Offset(6, -4),
      child: base,
    );
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final pending = ref.watch(pendingGrowthFocusCountProvider).valueOrNull ?? 0;

    final bodies = const [
      MoodListPage(),
      GrowthFocusPage(),
      SettingsPage(),
    ];

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(child: bodies[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: _tabIcon(
                _tabs[i].icon,
                badgeCount: i == _growthFocusTabIndex ? pending : 0,
              ),
              selectedIcon: _tabIcon(
                _tabs[i].icon,
                badgeCount: i == _growthFocusTabIndex ? pending : 0,
              ),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}
