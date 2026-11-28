import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/theme/mood_theme.dart';
import 'package:stday/features/island/widgets/story_seed_planting_overlay.dart';

void main() {
  testWidgets('planted sprout uses the island grass artwork', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 844,
          child: StorySeedPlantingOverlay(
            islandName: '财富岛',
            palette: defaultPalette,
            onCompleted: _noop,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    await tester.pump(const Duration(milliseconds: 1700));

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/decor/grass_01.png',
    );
    await tester.pump(const Duration(milliseconds: 1200));
  });
}

void _noop() {}
