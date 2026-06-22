import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/growth/level_unlock_preview.dart';
import 'package:stday/island/decor/decor_config.dart';

void main() {
  group('LevelUnlockPreviewAssets', () {
    test('buildingAssetForLevel returns exact unlock sprite', () {
      final asset = LevelUnlockPreviewAssets.buildingAssetForLevel(1);
      expect(asset, 'assets/images/buildings/starter_stone.png');
    });

    test('buildingAssetForLevel falls back to nearest lower level', () {
      final asset = LevelUnlockPreviewAssets.buildingAssetForLevel(2);
      expect(asset, isNotNull);
      expect(asset, contains('assets/images/buildings/'));
    });

    test('decorationAssetForLevel returns decor asset when available', () {
      final asset = LevelUnlockPreviewAssets.decorationAssetForLevel(1);
      expect(asset, isNotNull);
      expect(asset, 'assets/images/decor/grass_01.png');
    });

    for (var level = 1; level <= 20; level++) {
      test('levels 1-20 have preview assets', () {
        expect(
          LevelUnlockPreviewAssets.buildingAssetForLevel(level),
          isNotNull,
          reason: 'Lv.$level building preview',
        );
        expect(
          LevelUnlockPreviewAssets.decorationAssetForLevel(level),
          isNotNull,
          reason: 'Lv.$level decoration preview',
        );
        expect(
          DecorConfigs.primaryForLevel(level),
          isNotNull,
          reason: 'Lv.$level decor config',
        );
      });
    }
  });
}
