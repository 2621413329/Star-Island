import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/version/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('解析标准与带 build 的版本', () {
      expect(AppVersion.tryParse('1.3.1'), const AppVersion(1, 3, 1));
      expect(AppVersion.tryParse('1.3.1+7'), const AppVersion(1, 3, 1));
      expect(AppVersion.tryParse('v1.2'), const AppVersion(1, 2, 0));
    });

    test('非法输入返回 null', () {
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('abc'), isNull);
    });
  });

  group('requiresForceUpdate', () {
    test('低于最低版本需要强制更新', () {
      expect(
        requiresForceUpdate(
          localVersion: '1.2.0',
          minSupportedVersion: '1.3.0',
        ),
        isTrue,
      );
    });

    test('等于或高于最低版本不强制', () {
      expect(
        requiresForceUpdate(
          localVersion: '1.3.0',
          minSupportedVersion: '1.3.0',
        ),
        isFalse,
      );
      expect(
        requiresForceUpdate(
          localVersion: '1.3.1+7',
          minSupportedVersion: '1.3.0',
        ),
        isFalse,
      );
    });
  });
}
