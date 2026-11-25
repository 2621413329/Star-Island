import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stday/core/theme/mood_theme.dart';
import 'package:stday/features/more/settings_page.dart';
import 'package:stday/providers/app_providers.dart';

void main() {
  testWidgets('设置页收进提醒、声音、说明和账号操作', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moodPaletteProvider.overrideWithValue(paletteForMood(null)),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('记录提醒'), findsOneWidget);
    expect(find.text('声音设置'), findsOneWidget);
    expect(find.text('应用说明'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('注销账号'), findsOneWidget);
  });
}
