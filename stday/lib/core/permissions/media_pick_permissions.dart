import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 日常照片拍摄 / 选图前的运行时权限申请。
class MediaPickPermissions {
  /// 在打开相机或相册前申请对应权限；返回 `false` 时不应继续调起选图。
  static Future<bool> ensureForSource(
    ImageSource source, {
    required void Function(String message) onMessage,
  }) async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (source == ImageSource.camera) {
        return _requestPermission(
          Permission.camera,
          deniedMessage: '需要相机权限才能拍摄照片',
          blockedMessage: '请在系统设置中开启相机权限后再试',
          onMessage: onMessage,
        );
      }
      return _requestPermission(
        Permission.photos,
        deniedMessage: '需要照片权限才能从相册选择',
        blockedMessage: '请在系统设置中开启照片访问权限后再试',
        onMessage: onMessage,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // 国产 ROM 上 permission_handler 状态可能不准，申请失败也不阻断，交给 image_picker 再试。
      if (source == ImageSource.camera) {
        await _tryRequestPermission(Permission.camera);
      } else {
        await _tryRequestPermission(Permission.photos);
      }
    }
    return true;
  }

  static Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
    required String blockedMessage,
    required void Function(String message) onMessage,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      onMessage(blockedMessage);
      return false;
    }
    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    onMessage(deniedMessage);
    return false;
  }

  static Future<void> _tryRequestPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return;
    if (!status.isPermanentlyDenied) {
      await permission.request();
    }
  }
}
