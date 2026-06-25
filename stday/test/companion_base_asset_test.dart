import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/companion_base_asset.dart';

void main() {
  test('companionBaseAssetId maps AI emotion ids and legacy expressions', () {
    expect(companionBaseAssetId('kai_xin'), 'kai_xin');
    expect(companionBaseAssetId('happy'), 'kai_xin');
    expect(companionBaseAssetId('hopeful'), 'gan_dong');
    expect(companionBaseAssetId('proud'), 'xing_fen');
    expect(companionBaseAssetId('placeholder'), companionBasePlaceholderId);
  });

  test('companionBaseAssetCandidates prefers male/female then man/woman', () {
    final paths = companionBaseAssetCandidates(
      gender: 'male',
      assetId: 'ping_jing',
    );
    expect(paths.first, 'assets/images/companion/base/male_ping_jing.png');
    expect(paths, contains('assets/images/companion/base/man_ping_jing.png'));
  });

  test('companionBaseAssetPath uses male/female pinyin filename', () {
    expect(
      companionBaseAssetPath(gender: 'female', assetId: 'kai_xin'),
      'assets/images/companion/base/female_kai_xin.png',
    );
    expect(
      companionBaseAssetPath(gender: 'male', assetId: 'ping_jing'),
      'assets/images/companion/base/male_ping_jing.png',
    );
    expect(
      companionBaseAssetPath(gender: 'male', assetId: 'placeholder'),
      'assets/images/companion/base/male__placeholder.png',
    );
  });
}
