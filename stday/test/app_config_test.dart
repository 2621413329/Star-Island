import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/config/app_config.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('空值使用生产 HTTPS 域名', () {
      expect(AppConfig.normalizeApiBaseUrl(''), AppConfig.productionApiBaseUrl);
    });

    test('公网 HTTP 升级为 HTTPS 并去掉历史端口', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://39.106.134.222:9000'),
        'https://39.106.134.222',
      );
      expect(
        AppConfig.normalizeApiBaseUrl('http://api.lcxxingyu.fun:8090'),
        'https://api.lcxxingyu.fun',
      );
    });

    test('生产域名保持 HTTPS 无端口', () {
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
}
