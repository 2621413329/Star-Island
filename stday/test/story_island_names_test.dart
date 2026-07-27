import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/story_island_names.dart';

void main() {
  group('isDuplicateStoryIslandName', () {
    test('detects same full name', () {
      expect(
        isDuplicateStoryIslandName(
          candidateName: '工作岛',
          existingNames: const ['工作岛', '学业岛'],
        ),
        isTrue,
      );
    });

    test('treats stem and full name as same', () {
      expect(
        isDuplicateStoryIslandName(
          candidateName: '高考',
          existingNames: const ['高考岛'],
        ),
        isTrue,
      );
    });

    test('ignores case differences', () {
      expect(
        isDuplicateStoryIslandName(
          candidateName: 'Work',
          existingNames: const ['work岛'],
        ),
        isTrue,
      );
    });

    test('allows unused name', () {
      expect(
        isDuplicateStoryIslandName(
          candidateName: '跑步',
          existingNames: const ['工作岛', '学业岛'],
        ),
        isFalse,
      );
    });
  });
}
