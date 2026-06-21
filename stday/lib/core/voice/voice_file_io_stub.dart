import 'dart:typed_data';

Future<Uint8List> readVoiceFileBytes(String path) async {
  throw UnsupportedError('Voice file read is not supported on this platform');
}

Future<void> deleteVoiceFile(String path) async {}

Future<bool> voiceFileExists(String path) async => false;
