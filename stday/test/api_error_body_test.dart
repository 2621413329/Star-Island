import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/api/api_client.dart';

void main() {
  test('plain-text JSON error keeps the server message', () {
    final body = tryParseApiBody(
      '{"code":400,"message":"仅支持 m4a 格式语音","data":null}',
    );

    expect(apiMessageOf(body!), '仅支持 m4a 格式语音');
    expect(apiCodeOf(body['code']), 400);
  });

  test('html gateway page is not treated as an api body', () {
    expect(tryParseApiBody('<html><body>504 Gateway Time-out</body></html>'), isNull);
  });

  test('numeric code stored as a double still parses', () {
    expect(apiCodeOf(422.0), 422);
  });
}
