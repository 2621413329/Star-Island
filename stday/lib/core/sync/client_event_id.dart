import 'dart:math';

/// Generates client-side event ids used for idempotent sync requests.
class ClientEventId {
  static final Random _random = Random();

  static String next(String scope) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final salt = _random.nextInt(0x7fffffff).toRadixString(36);
    return '$scope-$now-$salt';
  }
}
