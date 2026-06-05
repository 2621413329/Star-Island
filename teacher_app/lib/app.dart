import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/mood_theme.dart';
import 'design_system/phone_viewport.dart';
import 'features/auth/teacher_login_page.dart';
import 'features/auth/teacher_register_page.dart';
import 'features/home/teacher_home_page.dart';
import 'providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: auth.isLoggedIn ? '/home' : '/login',
    redirect: (context, state) {
      final loggedIn = ref.read(authProvider).isLoggedIn;
      final onAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const TeacherLoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const TeacherRegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const TeacherHomePage()),
    ],
  );
});

class TeacherApp extends ConsumerWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '星屿·教师',
      theme: buildAppTheme(defaultPalette),
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.25),
          ),
          child: PhoneViewport(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
