import '../../data/models/profile_models.dart';

/// 登岛伙伴角色 id（与 RBAC 权限角色无关）。
class CompanionRoles {
  CompanionRoles._();

  static const xiaoXingzai = 'xiao_xingzai';
  static const xiaoGuangbao = 'xiao_guangbao';

  static const defaultRoleId = xiaoXingzai;

  static const List<String> selectableRoleIds = [xiaoXingzai, xiaoGuangbao];

  static const Map<String, String> displayNames = {
    xiaoXingzai: '小星仔',
    xiaoGuangbao: '小光宝',
  };

  /// 渲染层资源前缀：male → man_*, female → woman_*。
  static const Map<String, String> renderKeys = {
    xiaoXingzai: 'male',
    xiaoGuangbao: 'female',
  };

  static bool isValid(String? roleId) =>
      roleId != null && renderKeys.containsKey(roleId);

  static String nameFor(String? roleId) =>
      displayNames[roleId] ?? displayNames[defaultRoleId]!;

  static String? renderKey(String? roleId) => renderKeys[roleId];

  static String? fromLegacyGender(String? gender) {
    return switch (gender?.trim().toLowerCase()) {
      'male' || '男' => xiaoXingzai,
      'female' || 'girl' || '女' => xiaoGuangbao,
      _ => null,
    };
  }

  static String? resolveRoleId({
    String? companionRoleId,
    String? legacyGender,
  }) {
    if (isValid(companionRoleId)) return companionRoleId;
    return fromLegacyGender(legacyGender);
  }

  static String? resolveRenderKey({
    String? companionRoleId,
    String? legacyGender,
  }) {
    return renderKey(resolveRoleId(
      companionRoleId: companionRoleId,
      legacyGender: legacyGender,
    ));
  }
}

extension UserProfileCompanionRoleX on UserProfileModel {
  bool get hasCompanionRole =>
      CompanionRoles.isValid(companionRoleId) ||
      CompanionRoles.fromLegacyGender(gender) != null;
}
