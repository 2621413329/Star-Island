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

  test('companionBaseAssetPath uses pinyin filename', () {
    expect(
      companionBaseAssetPath(gender: 'female', assetId: 'kai_xin'),
      'assets/images/companion/base/female_kai_xin.png',
    );
    expect(
      companionBaseAssetPath(gender: 'male', assetId: 'placeholder'),
      'assets/images/companion/base/male__placeholder.png',
    );
  });
}
