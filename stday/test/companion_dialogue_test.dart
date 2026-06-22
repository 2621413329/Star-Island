import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/companion_dialogue.dart';

void main() {
  test('applyCompanionNickname replaces placeholder with nickname', () {
    const line = '{nickname}，今天辛苦啦';
    expect(applyCompanionNickname(line, '小明'), '小明，今天辛苦啦');
  });

  test('applyCompanionNickname falls back to 你 when nickname empty', () {
    const line = '{nickname}，今天辛苦啦';
    expect(applyCompanionNickname(line, null), '今天辛苦啦');
    expect(
      applyCompanionNickname('今天生活对我们{nickname}怎么样呀？', ''),
      '今天生活对你怎么样呀？',
    );
    expect(applyCompanionNickname('撑住，{nickname}', null), '撑住，你');
  });

  test('applyCompanionNicknameLines maps all lines', () {
    const lines = [
      '{nickname}，今天辛苦啦',
      '今天生活对我们{nickname}怎么样呀？',
    ];
    expect(
      applyCompanionNicknameLines(lines, '阿星'),
      ['阿星，今天辛苦啦', '今天生活对我们阿星怎么样呀？'],
    );
  });
}
