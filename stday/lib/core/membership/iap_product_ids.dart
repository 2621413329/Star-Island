/// App Store Connect 内购商品 ID（须与 member_products.product_id 一致）。
abstract final class IapProductIds {
  static const monthly = 'com.xiaoerlcx.app.vip.monthly';
  static const quarterly = 'com.xiaoerlcx.app.vip.quarterly';
  static const yearly = 'com.xiaoerlcx.app.vip.yearly';

  static const Set<String> all = {monthly, quarterly, yearly};

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
            subtitle: '自动续费，每月续订',
            promoPrice: '12',
            originalPrice: '12',
          ),
        quarterly => const VipPlanUi(
            title: '季卡',
            subtitle: '自动续费，每 3 个月续订',
            promoPrice: '28',
            originalPrice: '28',
            badge: '限时优惠',
          ),
        yearly => const VipPlanUi(
            title: '年卡',
            subtitle: '自动续费，每年续订',
            promoPrice: '98',
            originalPrice: '98',
            badge: '推荐',
          ),
        _ => VipPlanUi(
            title: label(productId),
            subtitle: 'VIP 套餐',
            promoPrice: '',
            originalPrice: '',
          ),
      };
}

class VipPlanUi {
  const VipPlanUi({
    required this.title,
    required this.subtitle,
    required this.promoPrice,
    required this.originalPrice,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String promoPrice;
  final String originalPrice;
  final String? badge;
}
