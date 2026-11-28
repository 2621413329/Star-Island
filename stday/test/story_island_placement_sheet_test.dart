import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stday/core/theme/mood_theme.dart';
import 'package:stday/data/models/profile_models.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/features/today/story_island_placement_sheet.dart';
import 'package:stday/providers/app_providers.dart';

void main() {
  testWidgets('放入岛屿时滚到当前选中的岛', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final labels = ['工作', '学业', '健康', '人际', '生活', '创作', '财富', '成就', '情感', '灵感'];
    final groups = [
      for (final label in labels)
        StoryIslandCategoryModel(
          id: label,
          label: label,
          islands: [
            StoryIslandModel(
              id: 'island-$label',
              categoryId: label,
              name: '$label岛',
            ),
          ],
        ),
    ];
    final moment = DailyMomentModel(
      id: 'moment-1',
      eventTags: const ['财务'],
      emotionTag: 'calm',
      storyIslandId: 'island-灵感',
      companionScene: 'idle',
      companionPose: 'breathing',
      momentDate: DateTime(2026, 11, 26),
      createdAt: DateTime(2026, 11, 26),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moodPaletteProvider.overrideWithValue(paletteForMood(null)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showStoryIslandPlacementSheet(
                        context: context,
                        moment: moment,
                        groups: groups,
                      );
                    },
                    child: const Text('打开'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    final tile = find.text('灵感岛');
    expect(list, findsOneWidget);
    expect(tile, findsOneWidget);
    final listRect = tester.getRect(list);
    final tileRect = tester.getRect(tile);
    expect(tileRect.top, greaterThanOrEqualTo(listRect.top - 1));
    expect(tileRect.bottom, lessThanOrEqualTo(listRect.bottom + 1));
    final position =
        tester.widget<ListView>(list).controller?.hasClients == true
            ? tester.widget<ListView>(list).controller!.offset
            : Scrollable.of(tester.element(tile)).position.pixels;
    expect(position, greaterThan(40));
  });
}
