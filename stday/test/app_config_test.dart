import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/config/app_config.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('空值使用生产 HTTP 域名', () {
      expect(AppConfig.normalizeApiBaseUrl(''), AppConfig.productionApiBaseUrl);
    });

    test('保留构建时传入的 HTTP 地址', () {
      expect(
        AppConfig.normalizeApiBaseUrl('http://39.106.134.222:8000'),
        'http://39.106.134.222:8000',
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
