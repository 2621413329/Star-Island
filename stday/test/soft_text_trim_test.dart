import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/soft_text_trim.dart';

void main() {
  group('softTrimText', () {
    test('returns original when within limit', () {
      expect(softTrimText('今天很开心。', 20), '今天很开心。');
    });

    test('breaks at punctuation instead of mid sentence', () {
      const text = '这周写了三条日常，工作有点忙，但周末去公园散步了，心情慢慢好起来。';
      final trimmed = softTrimText(text, 30);
      expect(trimmed.characters.length, lessThanOrEqualTo(30));
      const breakers = '。！？…；，、';
      expect(
        breakers.contains(trimmed.characters.last) ||
            trimmed.endsWith('…'),
        isTrue,
      );
    });

    test('uses ellipsis when no punctuation break found', () {
      final trimmed = softTrimText('abcdefghijklmnopqrstuvwxyz', 10);
      expect(trimmed.endsWith('…'), isTrue);
      expect(trimmed.length, lessThanOrEqualTo(10));
    });
  });
}
