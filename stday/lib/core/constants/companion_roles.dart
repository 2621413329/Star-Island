import '../../data/models/profile_models.dart';

/// 登岛伙伴角色 id（与 RBAC 权限角色无关）。
class CompanionRoles {
  CompanionRoles._();

  static const xiaoXingzai = 'xiao_xingzai';
  static const xiaoGuangbao = 'xiao_guangbao';
  static const yuan = 'yuan';
  static const meng = 'meng';

  static const defaultRoleId = xiaoXingzai;

  static const List<String> selectableRoleIds = [
    xiaoXingzai,
    xiaoGuangbao,
    yuan,
    meng,
  ];

  static const Set<String> premiumRoleIds = {yuan, meng};

  static const Map<String, String> displayNames = {
    xiaoXingzai: '小星仔',
    xiaoGuangbao: '小光宝',
    yuan: '小愿',
    meng: '小梦',
  };

  /// 选择页/注册页展示的简短介绍。
  static const Map<String, String> roleTaglines = {
    xiaoXingzai: '可可爱爱的小包子头',
    xiaoGuangbao: '漂漂亮亮的水滴头',
    yuan: '星屿会员专属的温柔伙伴',
    meng: '星屿会员专属的治愈伙伴',
  };

  static String taglineFor(String? roleId) =>
      roleTaglines[roleId] ?? roleTaglines[defaultRoleId]!;

  static const Map<String, String> roleDescriptions = {
    meng: '小梦总是望着夜空发呆，她喜欢把人们的幻想、期待与灵感悄悄收藏起来。\n\n'
        '她相信，每一个看似平凡的今天，都藏着通往未来的可能。当你写下故事时，她会默默替你守护那些还未实现的梦想。\n\n'
        '在漫长的成长旅程中，小梦愿意陪你一起，把每一个梦想慢慢照进现实。',
    yuan: '小愿喜欢收集人们心中的小小愿望，无论它是一次勇敢的尝试，还是一句默默许下的心愿，她都会认真珍藏。\n\n'
        '她相信，成长不是一蹴而就，而是无数个坚持累积而成。每一次记录、每一次努力，都会让愿望离实现更近一点。\n\n'
        '无论走得快还是慢，小愿都会陪着你，一起见证每一步成长。',
  };

  static String? descriptionFor(String? roleId) => roleDescriptions[roleId];

  /// 渲染层资源前缀：male → man_*, female → woman_*。
  static const Map<String, String> renderKeys = {
    xiaoXingzai: 'male',
    xiaoGuangbao: 'female',
    yuan: 'yuan',
    meng: 'meng',
  };

  static bool isValid(String? roleId) =>
      roleId != null && renderKeys.containsKey(roleId);

  static bool isPremium(String? roleId) =>
      roleId != null && premiumRoleIds.contains(roleId);

  static String nameFor(String? roleId) =>
      displayNames[roleId] ?? displayNames[defaultRoleId]!;

  /// 感受区块标题（编辑标签页）。
  static const moodFeelingSectionTitle = '心情感受';

  /// @deprecated 标签行已不再展示「小星感受 · xxx」，保留供兼容。
  static String emotionInsightPrefix(String? roleId) => moodFeelingSectionTitle;

  static String analyzingDailyMessage(String? roleId) =>
      '${nameFor(roleId)}正在理解你的日常…';

  static String analyzingVoiceMessage(String? roleId) =>
      '${nameFor(roleId)}正在理解你的语音…';

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
