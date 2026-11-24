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
