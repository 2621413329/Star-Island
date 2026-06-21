import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readVoiceFileBytes(String path) async {
  return File(path).readAsBytes();
}

Future<void> deleteVoiceFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<bool> voiceFileExists(String path) async {
  return File(path).exists();
}
