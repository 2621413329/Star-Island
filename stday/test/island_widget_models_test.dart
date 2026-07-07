import 'package:flutter_test/flutter_test.dart';

import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/services/island_widget_models.dart';

void main() {
  test('buildIslandWidgetPayload only includes current island tasks', () {
    const island = StoryIslandModel(
      id: 'island-a',
      categoryId: 'work',
      name: '工作岛屿',
      todayTasks: [
        StoryIslandTaskModel(
          id: 't1',
          islandId: 'island-a',
          title: '写周报',
          completedToday: false,
        ),
        StoryIslandTaskModel(
          id: 't2',
          islandId: 'island-a',
          title: 'PR review',
          completedToday: true,
        ),
      ],
    );

    final payload = buildIslandWidgetPayload(
      island: island,
      todayDate: '2026-07-06',
    );

    expect(payload.currentIslandId, 'island-a');
    expect(payload.islandName, '工作岛屿');
    expect(payload.completed, 1);
    expect(payload.total, 2);
    expect(payload.todayTasks.length, 2);
    expect(payload.todayTasks.every((t) => t.islandId == 'island-a'), isTrue);
    expect(payload.isGrowthMain, isFalse);
    expect(payload.displayLevel, 0);
    expect(payload.buildingPreviewLevel, 1);
  });

  test('buildIslandWidgetPayload truncates to three tasks', () {
    final island = StoryIslandModel(
      id: 'island-b',
      categoryId: 'study',
      name: '学习岛屿',
      todayTasks: List.generate(
        5,
        (index) => StoryIslandTaskModel(
          id: 't$index',
          islandId: 'island-b',
          title: '任务 $index',
        ),
      ),
    );

    final payload = buildIslandWidgetPayload(
      island: island,
      todayDate: '2026-07-06',
    );

    expect(payload.total, 5);
    expect(payload.todayTasks.length, 3);
  });
}
