import '../../core/utils/api_datetime.dart';

class IapVerifyResultModel {
  const IapVerifyResultModel({
    required this.productId,
    required this.transactionId,
    required this.isActive,
    required this.entitlementStatus,
    this.expireTime,
    this.environment,
  });

  final String productId;
  final String transactionId;
  final DateTime? expireTime;
  final String? environment;
  final bool isActive;
  final String entitlementStatus;

  factory IapVerifyResultModel.fromJson(Map<String, dynamic> json) {
    return IapVerifyResultModel(
      productId: json['product_id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      expireTime: parseApiDateTime(json['expire_time']),
      environment: json['environment'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      entitlementStatus: json['entitlement_status'] as String? ?? '',
    );
  }
}
