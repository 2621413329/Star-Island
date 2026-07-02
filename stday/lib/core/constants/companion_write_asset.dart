import 'companion_roles.dart';

/// 「记录今天的故事」等写作入口使用的角色立绘资源。
///
/// 新增角色时：
/// 1. 将 PNG 放入 [assetDir]
/// 2. 在 [assetFileByRoleId] 增加 `CompanionRoles.xxx → 文件名`
/// 3. 若为新角色 id，同步更新 [CompanionRoles]
abstract final class CompanionWriteAssets {
  static const assetDir = 'assets/images/companion/wright';

  /// 角色 id → 文件名（不含目录）。
  static const assetFileByRoleId = <String, String>{
    CompanionRoles.xiaoXingzai: 'xing_wgt.png',
    CompanionRoles.xiaoGuangbao: 'guang_wgt.png',
  };

  static String? assetFileFor(String? roleId) {
    final resolved = CompanionRoles.resolveRoleId(
      companionRoleId: roleId,
    );
    if (resolved == null) return assetFileByRoleId[CompanionRoles.defaultRoleId];
    return assetFileByRoleId[resolved];
  }

  static String assetPathFor(String? roleId) {
    final file = assetFileFor(roleId) ??
        assetFileByRoleId[CompanionRoles.defaultRoleId]!;
    return '$assetDir/$file';
  }
}
