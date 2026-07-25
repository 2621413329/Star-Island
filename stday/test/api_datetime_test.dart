import 'package:flutter_test/flutter_test.dart';
import 'package:stday/core/utils/api_datetime.dart';

void main() {
  test('parseApiDateTime treats naive ISO as UTC', () {
    final parsed = parseApiDateTime('2026-10-25T00:00:00');
    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
    expect(parsed.year, 2026);
    expect(parsed.month, 10);
    expect(parsed.day, 25);
  });

  test('parseApiDateTime keeps explicit UTC offset', () {
    final parsed = parseApiDateTime('2026-10-25T00:00:00Z');
    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
    expect(formatMembershipExpireDate(parsed), contains('2026年'));
  });

  test('parseApiDateTime supports epoch millis', () {
    final parsed = parseApiDateTime(1761350400000); // 2025-10-25 UTC approx
    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
  });
}
