import '../../data/models/profile_models.dart';
import 'companion_spec.dart';

/// 当前用户小人的基础样貌（全局统一对象）。
///
/// 修改此对象即可影响所有页面中该用户小人的形体、性别等基础外观；
/// 爱心、小球等配饰与单次表演由 [CompanionStoryContext] 承载。
class UserCompanion {
  const UserCompanion({
    this.profileStyle = 'chibi',
    this.gender,
  });

  final String profileStyle;
  final String? gender;

  /// 绘制层使用的样式 id（如 mindscape / chibi_legacy）。
  String get renderStyle {
    if (profileStyle == 'chibi' || profileStyle == 'normal') return 'mindscape';
    return profileStyle;
  }

  factory UserCompanion.fromProfile(UserProfileModel? profile) {
    return UserCompanion(
      profileStyle: profile?.companionStyle ?? 'chibi',
      gender: profile?.gender,
    );
  }

  UserCompanion copyWith({
    String? profileStyle,
    String? gender,
  }) {
    return UserCompanion(
      profileStyle: profileStyle ?? this.profileStyle,
      gender: gender ?? this.gender,
    );
  }
}

/// 某条心情故事中的小人表演与配饰。
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
