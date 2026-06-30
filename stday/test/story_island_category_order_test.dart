import 'package:flutter_test/flutter_test.dart';
import 'package:stday/data/models/story_island_models.dart';
import 'package:stday/providers/app_providers.dart';

void main() {
  test('sortStoryIslandCategories respects user order and appends unknown', () {
    const categories = [
      StoryIslandCategoryModel(
        id: 'work',
        label: '工作',
        icon: 'work',
        color: '#000',
        sortOrder: 10,
      ),
      StoryIslandCategoryModel(
        id: 'study',
        label: '学业',
        icon: 'school',
        color: '#000',
        sortOrder: 20,
      ),
      StoryIslandCategoryModel(
        id: 'life',
        label: '生活',
        icon: 'home',
        color: '#000',
        sortOrder: 50,
      ),
    ];

    final sorted = sortStoryIslandCategories(
      categories,
      const ['life', 'work'],
    );

    expect(sorted.map((item) => item.id).toList(), ['life', 'work', 'study']);
  });

  test('storyIslandCategoryOrderFromPrefs ignores invalid entries', () {
    expect(
      storyIslandCategoryOrderFromPrefs({
        storyIslandCategoryOrderKey: ['work', '', 3, 'study'],
      }),
      ['work', 'study'],
    );
  });
}
