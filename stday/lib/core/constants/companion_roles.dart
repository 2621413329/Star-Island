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
    xiaoXingzai: '活泼小包子头 · 行动派成长搭子 · 把今天的小事一颗颗装进小岛',
    xiaoGuangbao: '温柔水滴头 · 倾听型心情伙伴 · 把心情擦亮，轻轻照亮每一天',
    yuan: '星屿会员专属的温柔伙伴',
    meng: '星屿会员专属的治愈伙伴',
  };

  static String taglineFor(String? roleId) =>
      roleTaglines[roleId] ?? roleTaglines[defaultRoleId]!;

  /// 角色性格关键词，用于选择卡补充介绍。
  static const Map<String, List<String>> roleTraits = {
    xiaoXingzai: ['活泼好奇', '行动派', '把小事当宝藏', '陪你坚持打卡', '会加油欢呼', '擅长开场'],
    xiaoGuangbao: ['细腻温柔', '善于倾听', '安抚情绪', '把光留给今天', '不催促', '懂你没说完的话'],
    yuan: ['珍藏心愿', '温柔守望', '见证坚持'],
    meng: ['守护梦想', '安静陪伴', '照进未来'],
  };

  static List<String> traitsFor(String? roleId) =>
      roleTraits[roleId] ?? roleTraits[defaultRoleId]!;

  static const Map<String, String> roleDescriptions = {
    xiaoXingzai: '小星仔顶着圆圆的小包子头，总是第一个冲到你身边。他像一颗会跑的小星星，专长是把「今天」拆成一件件小事：完成的待办、随手记下的心情、一次小小的勇敢、甚至按时休息，他都会认真捡起来，一颗一颗放进星屿的口袋。\n\n'
        '他相信，成长不必轰轰烈烈。认真做完一件事、把想法说出口、哪怕只是迈出半步，都值得被看见。记录的时候，他会在旁边轻轻点头，像在说：「今天也很好。」你卡住时，他更愿意先拉你动起来——先写一句、先勾一项，再慢慢把世界搭起来。\n\n'
        '性格上，他是活泼的行动伙伴：催你迈出第一步，也记得夸你坚持下来。晴天他跟你一起晒太阳，雨天他帮你把故事收进小岛；升级、打卡、完成小岛任务时，他总会第一个给你加油。\n\n'
        '适合你，如果你希望身边有人提醒「先做起来」、陪你把每天的小事慢慢建成世界——选小星仔就对了。',
    xiaoGuangbao: '小光宝顶着亮亮的水滴头，像一滴温柔的光落在岛上。她不急着推你往前冲，更擅长听懂你没说完的话：写日常时，她会悄悄把心情擦得更清晰一点；情绪乱的时候，她会先陪你停一停，再帮你把今天轻轻安放好。\n\n'
        '她相信，被看见的情绪才会变轻，被写下的故事才会留下痕迹。每一次记录，都是她替你点亮的一盏小灯——不必完美，只要真实就好。累了她不催，乱了她帮你理一理；你愿意说时，她认真听；你不想说时，她也守着那点光，不让今天被悄悄吞掉。\n\n'
        '性格上，她是细腻的倾听伙伴：安抚、理解、把感受翻译成可以留下的痕迹。晨光里她提醒你关照自己，夜里她帮你把一天的心情收进星屿。\n\n'
        '适合你，如果你希望身边有人先懂你、再陪你慢慢记录——选小光宝就对了。',
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
