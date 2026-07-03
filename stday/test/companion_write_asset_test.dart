import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/constants/companion_roles.dart';
import 'package:stday/core/constants/companion_write_asset.dart';

void main() {
  test('CompanionWriteAssets maps xiao xing and xiao guang roles', () {
    expect(
      CompanionWriteAssets.assetPathFor(CompanionRoles.xiaoXingzai),
      'assets/images/companion/wright/xing_wgt.png',
    );
    expect(
      CompanionWriteAssets.assetPathFor(CompanionRoles.xiaoGuangbao),
      'assets/images/companion/wright/guang_wgt.png',
    );
  });

  test('CompanionWriteAssets falls back to default role', () {
    expect(
      CompanionWriteAssets.assetPathFor(null),
      CompanionWriteAssets.assetPathFor(CompanionRoles.defaultRoleId),
    );
    expect(
      CompanionWriteAssets.assetPathFor('unknown_role'),
      CompanionWriteAssets.assetPathFor(CompanionRoles.defaultRoleId),
    );
  });

  test('CompanionWriteAssets resolves legacy gender to write asset', () {
    expect(
      CompanionWriteAssets.assetPathFor(
        CompanionRoles.fromLegacyGender('female'),
      ),
      'assets/images/companion/wright/guang_wgt.png',
    );
    expect(
      CompanionWriteAssets.assetPathFor(
        CompanionRoles.fromLegacyGender('male'),
      ),
      'assets/images/companion/wright/xing_wgt.png',
    );
  });
}
