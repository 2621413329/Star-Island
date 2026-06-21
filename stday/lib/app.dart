import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n_extension.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/mood_theme.dart';
import 'design_system/app_startup_splash.dart';
import 'design_system/adaptive_viewport.dart';
import 'providers/app_providers.dart';
import 'providers/bootstrap_provider.dart';
import 'router/app_router.dart';

class StdayApp extends ConsumerWidget {
  const StdayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final palette = ref.watch(moodPaletteProvider);
    final localeSettings = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: '星屿',
      debugShowCheckedModeBanner: false,
      locale: localeSettings.valueOrNull?.locale ?? const Locale('zh', 'CN'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('zh', 'CN');
        for (final supportedLocale in supported) {
          if (supportedLocale.languageCode == locale.languageCode &&
              (supportedLocale.countryCode == null ||
                  locale.countryCode == null ||
                  supportedLocale.countryCode == locale.countryCode)) {
            return supportedLocale;
          }
        }
        if (locale.languageCode == 'zh') return const Locale('zh', 'CN');
        if (locale.languageCode == 'en') return const Locale('en');
        return const Locale('zh', 'CN');
      },
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
              AdaptiveViewport(child: child ?? const SizedBox.shrink()),
              if (!settled) const AppStartupSplash(),
            ],
          ),
        );
      },
    );
  }
}
