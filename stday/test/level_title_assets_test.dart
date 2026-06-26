import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/growth_system.dart';
import 'package:stday/core/growth/level_title_assets.dart';

void main() {
  test('title asset paths use pinyin filenames for Lv1-Lv20', () {
    expect(
      LevelTitleAssets.assetPathForLevel(1),
      'assets/images/titles/lv01_chuxinzhe.png',
    );
    expect(
      LevelTitleAssets.assetPathForLevel(18),
      'assets/images/titles/lv18_xingchenshizhe.png',
    );
    expect(LevelTitleAssets.pinyinByLevel.length, GrowthSystem.maxLevel);
  });
}
