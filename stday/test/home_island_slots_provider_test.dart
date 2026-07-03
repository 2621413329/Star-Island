import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/features/home/providers/home_island_slots_provider.dart';

StoryIslandModel _island(String id, int level, {int growth = 0}) {
  return StoryIslandModel(
    id: id,
    categoryId: 'work',
    name: id,
    sizeKind: 'medium',
    currentLevel: level,
    growthValue: growth,
  );
}

void main() {
  test('topStoryIslandsByLevel returns islands sorted by level desc', () {
    final merged = [
      StoryIslandCategoryModel(
        id: 'work',
        label: '工作',
        icon: 'work',
        color: '#000',
        sortOrder: 0,
        islands: [
          _island('w-high', 10, growth: 50),
          _island('w-mid', 6, growth: 80),
          _island('w-low', 3),
        ],
      ),
      const StoryIslandCategoryModel(
        id: 'study',
        label: '学业',
        icon: 'school',
        color: '#000',
        sortOrder: 1,
        islands: [
          StoryIslandModel(
            id: 's1',
            categoryId: 'study',
            name: '学业岛',
            sizeKind: 'medium',
            currentLevel: 8,
            growthValue: 10,
          ),
        ],
      ),
    ];

    final top = topStoryIslandsByLevel(merged);
    expect(top.map((e) => e.id).toList(), ['w-high', 's1', 'w-mid', 'w-low']);
  });

  test('topStoryIslandsByLevel breaks ties by growth value', () {
    final groups = [
      StoryIslandCategoryModel(
        id: 'work',
        label: '工作',
        icon: 'work',
        color: '#000',
        sortOrder: 0,
        islands: [
          _island('a', 5, growth: 20),
          _island('b', 5, growth: 40),
        ],
      ),
    ];

    final top = topStoryIslandsByLevel(groups, limit: 2);
    expect(top.map((e) => e.id).toList(), ['b', 'a']);
  });
}
