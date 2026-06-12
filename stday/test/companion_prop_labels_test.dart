import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/companion_prop_labels.dart';
import 'package:stday/features/more/companion_prop_badge_detail.dart';

void main() {
  test('game asset stem resolves to Chinese title', () {
    expect(
      companionPropDisplayTitle(
        prop: 'interest__game',
        assetPath: 'assets/images/companion/props/family/game.png',
      ),
      '游戏',
    );
  });

  test('stored prop_label has priority', () {
    expect(
      CompanionPropLabels.resolve(
        prop: 'game',
        assetPath: 'assets/images/companion/props/family/game.png',
        storedLabel: '棋盘游戏',
      ),
      '棋盘游戏',
    );
  });
}
