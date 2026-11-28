import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stday/core/l10n/locale_controller.dart';
import 'package:stday/data/models/profile_models.dart';
import 'package:stday/core/theme/mood_theme.dart';
import 'package:stday/features/today/write_story_page.dart';
import 'package:stday/l10n/app_localizations.dart';
import 'package:stday/providers/app_providers.dart';
import 'package:stday/providers/member_provider.dart';

void main() {
  testWidgets('记录面板跟着手指上下移动', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moodPaletteProvider.overrideWithValue(paletteForMood(null)),
          isVipProvider.overrideWithValue(false),
          profileProvider.overrideWith(_StillProfile.new),
          localeControllerProvider.overrideWith(_ZhLocale.new),
        ],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WriteStoryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('今天发生了什么？');
    expect(title, findsWidgets);
    final before = tester.getRect(title.first).top;
    final gesture = await tester.startGesture(
      tester.getCenter(title.first),
    );
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump();
    final during = tester.getRect(title.first).top;
    expect(during - before, greaterThan(120));

    await gesture.moveBy(const Offset(0, -140));
    await tester.pump();
    final back = tester.getRect(title.first).top;
    expect(before + 50, greaterThan(back));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}

class _StillProfile extends ProfileNotifier {
  @override
  Future<UserProfileModel?> build() async => null;
}

class _ZhLocale extends LocaleController {
  @override
  Future<LocaleSettings> build() async {
    return const LocaleSettings(
      locale: Locale('zh', 'CN'),
      defaultLocaleTag: 'zh_CN',
    );
  }
}
