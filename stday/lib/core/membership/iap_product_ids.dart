/// App Store Connect 内购商品 ID（须与 member_products.product_id 一致）。
abstract final class IapProductIds {
  static const monthly = 'com.xiaoerlcx.app.vip.monthly';
  static const quarterly = 'com.xiaoerlcx.app.vip.quarterly';
  static const yearly = 'com.xiaoerlcx.app.vip.yearly';

  static const Set<String> all = {monthly, quarterly, yearly};

  /// 自动续订订阅服务名称（审核披露用）。
  static const serviceName = '星屿会员';

  static String label(String productId) => switch (productId) {
        monthly => 'VIP 月卡',
        quarterly => 'VIP 季卡',
        yearly => 'VIP 年卡',
        _ => productId,
      };

  static int sortOrder(String productId) => switch (productId) {
        monthly => 0,
        quarterly => 1,
        yearly => 2,
        _ => 99,
      };

  static VipPlanUi plan(String productId) => switch (productId) {
        monthly => const VipPlanUi(
            title: '月卡',
            displayTitle: '星屿会员 · 月卡',
            periodShort: '1 个月',
            periodLabel: '订阅时长：1 个月，自动续费',
            subtitle: '自动续费，每月续订',
          ),
        quarterly => const VipPlanUi(
            title: '季卡',
            displayTitle: '星屿会员 · 季卡',
            periodShort: '3 个月',
            periodLabel: '订阅时长：3 个月，自动续费',
            subtitle: '自动续费，每 3 个月续订',
            badge: '限时优惠',
          ),
        yearly => const VipPlanUi(
            title: '年卡',
            displayTitle: '星屿会员 · 年卡',
            periodShort: '12 个月',
            periodLabel: '订阅时长：12 个月，自动续费',
            subtitle: '自动续费，每年续订',
            badge: '推荐',
          ),
        _ => VipPlanUi(
            title: label(productId),
            displayTitle: label(productId),
            periodShort: '订阅',
            periodLabel: '自动续费订阅',
            subtitle: 'VIP 套餐',
          ),
      };
}

class VipPlanUi {
  const VipPlanUi({
    required this.title,
    required this.displayTitle,
    required this.periodShort,
    required this.periodLabel,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String displayTitle;
  final String periodShort;
  final String periodLabel;
  final String subtitle;
  final String? badge;
}
