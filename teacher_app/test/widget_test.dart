import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:teacher_app/app.dart';

void main() {
  testWidgets('TeacherApp builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeacherApp()));
    expect(find.text('教师工作台'), findsOneWidget);
  });
}
