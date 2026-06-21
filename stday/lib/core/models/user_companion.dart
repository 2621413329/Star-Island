import '../constants/companion_roles.dart';
import '../../data/models/profile_models.dart';
import 'companion_spec.dart';

/// 当前用户小人的基础样貌（全局统一对象）。
///
/// [companionRoleId] 为登岛角色；[renderGender] 供绘制层选择男女向资源。
class UserCompanion {
  const UserCompanion({
    this.profileStyle = 'chibi',
    this.companionRoleId,
    this.legacyGender,
  });

  final String profileStyle;
  final String? companionRoleId;
  final String? legacyGender;

  String? get resolvedRoleId => CompanionRoles.resolveRoleId(
        companionRoleId: companionRoleId,
        legacyGender: legacyGender,
      );

  /// 绘制层使用的样式 id（Growth Island 2.0 统一 cozy 3D 白小人）。
  String get renderStyle {
    if (profileStyle == 'chibi' ||
        profileStyle == 'normal' ||
        profileStyle == 'mindscape') {
      return 'cozy';
    }
    return profileStyle;
  }

  /// 兼容旧调用：等同 renderGender。
  String? get gender => renderGender;

  String? get renderGender => CompanionRoles.resolveRenderKey(
        companionRoleId: companionRoleId,
        legacyGender: legacyGender,
      );

  factory UserCompanion.fromProfile(UserProfileModel? profile) {
    return UserCompanion(
      profileStyle: profile?.companionStyle ?? 'chibi',
      companionRoleId: profile?.companionRoleId,
      legacyGender: profile?.gender,
    );
  }

  UserCompanion copyWith({
    String? profileStyle,
    String? companionRoleId,
    String? legacyGender,
  }) {
    return UserCompanion(
      profileStyle: profileStyle ?? this.profileStyle,
      companionRoleId: companionRoleId ?? this.companionRoleId,
      legacyGender: legacyGender ?? this.legacyGender,
    );
  }
}

/// 某条心情日常中的小人表演与配饰。
class CompanionStoryContext {
  const CompanionStoryContext({
    required this.spec,
    this.scene = 'stargaze',
    this.pose = 'breathing',
  });

  final CompanionSpec spec;
  final String scene;
  final String pose;

  factory CompanionStoryContext.fromMoment(DailyMomentModel moment) {
    return CompanionStoryContext(
      spec: moment.companionSpec,
      scene: moment.companionScene,
      pose: moment.companionPose,
    );
  }
}
