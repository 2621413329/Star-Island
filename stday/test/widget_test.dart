import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stday/app.dart';
import 'package:stday/core/bootstrap/app_bootstrap.dart';
import 'package:stday/providers/bootstrap_provider.dart';

void main() {
  testWidgets('StdayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWithValue(const AppBootstrap()),
        ],
        child: const StdayApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(StdayApp), findsOneWidget);
  });
}
