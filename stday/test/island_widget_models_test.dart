import 'package:flutter_test/flutter_test.dart';

import 'package:stday/data/models/profile_models.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/services/island_widget_models.dart';

void main() {
  test('buildIslandWidgetPayload drops daily tasks and shows an empty review', () {
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
    expect(payload.completed, 0);
    expect(payload.total, 0);
    expect(payload.todayTasks, isEmpty);
    expect(payload.reviewTitle, '工作岛屿等待新记录');
    expect(payload.reviewBody, contains('写下今天的一件小事'));
    expect(payload.isGrowthMain, isFalse);
    expect(payload.displayLevel, 0);
    expect(payload.buildingPreviewLevel, 1);
    expect(payload.islandStatus, '平静');
  });

  test('buildIslandWidgetPayload reviews today moments instead of tasks', () {
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
    final moment = DailyMomentModel(
      id: 'm1',
      eventTags: const ['阅读'],
      emotionTag: 'calm',
      primaryTag: '阅读',
      aiEmotion: '平静',
      storyIslandId: 'island-b',
      companionScene: 'island',
      companionPose: 'stand',
      momentDate: DateTime(2026, 7, 6),
      createdAt: DateTime(2026, 7, 6),
    );

    final payload = buildIslandWidgetPayload(
      island: island,
      todayDate: '2026-07-06',
      todayMoments: [moment],
    );

    expect(payload.todayTasks, isEmpty);
    expect(payload.todayMomentCount, 1);
    expect(payload.reviewTitle, '学习岛屿今日回顾');
    expect(payload.reviewBody, contains('阅读'));
    expect(payload.focusLabel, contains('今日 1 条'));
  });
}
