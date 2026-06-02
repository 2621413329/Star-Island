import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/mood_theme.dart';
import 'providers/app_providers.dart';
import 'router/app_router.dart';

class StdayApp extends ConsumerWidget {
  const StdayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final palette = ref.watch(moodPaletteProvider);

    return MaterialApp.router(
      title: '成长小岛',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette),
      routerConfig: router,
    );
  }
}
