import 'package:flutter_test/flutter_test.dart';
import 'package:stday/world/island/detail_building_spread.dart';
import 'package:stday/world/island/painted_island_asset.dart';
import 'package:stday/world/island/painted_island_pits.dart';

void main() {
  test('detail page keeps building bodies from covering each other', () {
    const aliases = {
      'growth_house_lv2': 'growth_house',
      'lighthouse_base': 'lighthouse',
    };
    final ids = PaintedIslandPits.buildings.keys.toList()..sort();
    final overlaps = <String>[];
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = ids[i];
        final b = ids[j];
        if (aliases[a] == b || aliases[b] == a) continue;
        final aFoot = DetailBuildingSpread.place(a, PaintedIslandPits.buildings[a]!, 1.42);
        final bFoot = DetailBuildingSpread.place(b, PaintedIslandPits.buildings[b]!, 1.42);
        final aRect = DetailBuildingSpread.contentRect(a, aFoot, pad: 0.004);
        final bRect = DetailBuildingSpread.contentRect(b, bFoot, pad: 0.004);
        if (aRect.overlaps(bRect)) {
          overlaps.add(
            '$a ${aFoot.dx.toStringAsFixed(3)},${aFoot.dy.toStringAsFixed(3)} '
            'vs $b ${bFoot.dx.toStringAsFixed(3)},${bFoot.dy.toStringAsFixed(3)}',
          );
        }
      }
    }
    expect(overlaps, isEmpty);
  });

  test('shore trees only cover the feet of what stands behind them', () {
    const trees = [
      'tree_small_01',
      'tree_small_02',
      'tree_small_03',
      'tree_small_04',
      'tree_large_01',
      'tree_large_01b',
      'tree_large_01c',
      'tree_large_02',
      'tree_large_02b',
      'tree_large_02c',
      'life_tree_01',
    ];
    final buildings = PaintedIslandPits.buildings.entries
        .where(
          (entry) =>
              entry.key != 'lighthouse_base' &&
              entry.key != 'growth_house_lv2',
        )
        .toList();
    final bad = <String>[];
    for (final tree in trees) {
      final crown = DetailBuildingSpread.treeContentRect(
        tree,
        PaintedIslandPits.decor(tree),
      );
      for (final building in buildings) {
        final body = DetailBuildingSpread.contentRect(
          building.key,
          building.value,
          pad: 0,
        );
        if (DetailBuildingSpread.coversAbnormally(crown, body)) {
          bad.add('$tree vs ${building.key}');
        }
      }
      for (final other in trees) {
        if (other.compareTo(tree) <= 0) continue;
        final otherCrown = DetailBuildingSpread.treeContentRect(
          other,
          PaintedIslandPits.decor(other),
        );
        if (DetailBuildingSpread.coversAbnormally(crown, otherCrown)) {
          bad.add('$tree vs $other');
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('stones stand off building bodies', () {
    for (final stone in ['stone_01', 'stone_02']) {
      final foot = PaintedIslandPits.decor(stone);
      for (final building in PaintedIslandPits.buildings.entries) {
        if (building.key == 'lighthouse_base' ||
            building.key == 'growth_house_lv2') {
          continue;
        }
        final body = DetailBuildingSpread.contentRect(
          building.key,
          building.value,
        );
        expect(
          body.contains(foot),
          isFalse,
          reason: '$stone sits on ${building.key}',
        );
      }
    }
  });

  test('mailbox stands taller than the flowerbed', () {
    expect(
      DetailBuildingSpread.roleFor('memory_mailbox'),
      greaterThan(DetailBuildingSpread.roleFor('habit_flowerbed')),
    );
    expect(
      DetailBuildingSpread.roleFor('memory_mailbox'),
      lessThan(DetailBuildingSpread.roleFor('growth_house')),
    );
  });

  test('preview keeps the painted pit', () {
    final pit = PaintedIslandPits.building('memory_mailbox')!;
    expect(
      DetailBuildingSpread.place('memory_mailbox', pit, 1),
      pit,
    );
  });

  test('detail buildings stay smaller than the enlarged plate', () {
    expect(DetailBuildingSpread.bodyScale, lessThan(1));
    expect(PaintedIslandAsset.detailScale, greaterThan(1));
  });
}
