import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/mood_theme.dart';
import 'design_system/app_startup_splash.dart';
import 'design_system/phone_viewport.dart';
import 'providers/app_providers.dart';
import 'providers/bootstrap_provider.dart';
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
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(palette),
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final settled = ref.watch(startupSettledProvider);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.25),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhoneViewport(child: child ?? const SizedBox.shrink()),
              if (!settled)
                const AppStartupSplash(message: '正在唤醒成长小岛…'),
            ],
          ),
        );
      },
    );
  }
}
