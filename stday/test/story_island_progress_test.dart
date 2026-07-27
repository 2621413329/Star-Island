import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/features/island/story_island_progress.dart';

StoryIslandModel _island({
  int growthValue = 0,
  int storyCount = 0,
  int currentLevel = 0,
}) {
  return StoryIslandModel(
    id: 'i1',
    categoryId: 'work',
    name: '工作角',
    growthValue: growthValue,
    storyCount: storyCount,
    currentLevel: currentLevel,
  );
}

void main() {
  group('StoryIsland opened / level badge', () {
    test('no content stays closed', () {
      final island = _island();
      expect(island.isOpened, isFalse);
      expect(storyIslandLevelBadge(island), '待开启');
      expect(storyIslandHudLevelBadge(island), '待开启');
    });

    test('growth > 0 opens island as Lv.0 before Lv1', () {
      final island = _island(growthValue: 5, storyCount: 1, currentLevel: 0);
      expect(island.isOpened, isTrue);
      expect(storyIslandLevelBadge(island), 'Lv.0');
      expect(storyIslandHudLevelBadge(island), 'Lv.0/10');
      expect(storyIslandLevelLabel(island), 'Lv.0');
    });

    test('storyCount alone opens island', () {
      final island = _island(storyCount: 1, currentLevel: 0);
      expect(island.isOpened, isTrue);
      expect(storyIslandLevelBadge(island), 'Lv.0');
    });

    test('meets Lv1 shows level number', () {
      final island = _island(growthValue: 30, storyCount: 2, currentLevel: 1);
      expect(storyIslandLevelBadge(island), 'Lv.1');
    });
  });
}
