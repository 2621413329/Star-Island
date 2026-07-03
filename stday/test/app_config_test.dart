import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/config/app_config.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('空值使用生产 HTTPS 域名', () {
      expect(AppConfig.normalizeApiBaseUrl(''), AppConfig.productionApiBaseUrl);
      expect(AppConfig.productionApiBaseUrl, 'https://api.lcxxingyu.fun');
    });

    test('保留构建时传入的 HTTPS 地址', () {
      expect(
        AppConfig.normalizeApiBaseUrl('https://api.lcxxingyu.fun'),
        'https://api.lcxxingyu.fun',
      );
    });

    test('本机开发地址不改动', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://127.0.0.1:9000'),
        'http://127.0.0.1:9000',
      );
    });
  });

  group('buildApiBaseUrl', () {
    test('生产域名不带端口', () {
      expect(
        AppConfig.buildApiBaseUrl(scheme: 'https', host: 'api.lcxxingyu.fun'),
        'https://api.lcxxingyu.fun',
      );
    });
  });
}
