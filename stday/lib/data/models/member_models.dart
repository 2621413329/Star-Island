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
    final expireRaw = json['expire_time'];
    return MemberMeModel(
      isVip: json['is_vip'] as bool? ?? false,
      membershipType: json['membership_type'] as String?,
      expireTime: expireRaw == null
          ? null
          : DateTime.tryParse(expireRaw.toString())?.toUtc(),
      source: json['source'] as String?,
    );
  }
}
