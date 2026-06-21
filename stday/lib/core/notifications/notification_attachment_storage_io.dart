import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> persistNotificationIconPng(
  String assetPath,
  Uint8List bytes,
) async {
  final dir = await getApplicationSupportDirectory();
  final iconsDir = Directory('${dir.path}/reminder_notification_icons');
  if (!await iconsDir.exists()) {
    await iconsDir.create(recursive: true);
  }
  final fileName = 'icon_${assetPath.hashCode.abs()}.png';
  final file = File('${iconsDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<bool> notificationIconFileExists(String path) async {
  return File(path).exists();
}
