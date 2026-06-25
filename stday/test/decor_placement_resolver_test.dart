import 'package:flutter_test/flutter_test.dart';
import 'package:stday/island/decor/decor_config.dart';
import 'package:stday/island/decor/decor_placement_resolver.dart';

void main() {
  test('DecorPlacementResolver moves decor out of protagonist rear zone', () {
    const resolver = DecorPlacementResolver();
    final positions = resolver.resolve(DecorConfigs.unlockedAt(5));

    for (final entry in positions.entries) {
      final p = entry.value;
      expect(
        DecorPlacementResolver.protagonistRearZone.contains(p),
        isFalse,
        reason: '${entry.key} should not sit behind protagonist at $p',
      );
    }

    final tree = positions['tree_small_01'];
    expect(tree, isNotNull);
    expect((tree!.dx - 0.5).abs(), greaterThan(0.08));
  });
}
