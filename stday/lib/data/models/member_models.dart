import '../../core/utils/api_datetime.dart';

class MemberMeModel {
  const MemberMeModel({
    required this.isVip,
    this.membershipType,
    this.expireTime,
    this.source,
  });

  final bool isVip;
  final String? membershipType;
  final DateTime? expireTime;
  final String? source;

  factory MemberMeModel.fromJson(Map<String, dynamic> json) {
    return MemberMeModel(
      isVip: json['is_vip'] as bool? ?? false,
      membershipType: json['membership_type'] as String?,
      expireTime: parseApiDateTime(json['expire_time']),
      source: json['source'] as String?,
    );
  }
}
