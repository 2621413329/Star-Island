/// App Store Connect 内购商品 ID（须与 member_products.product_id 一致）。
abstract final class IapProductIds {
  static const monthly = 'com.xiaoerlcx.app.vip.monthly';
  static const yearly = 'com.xiaoerlcx.app.vip.yearly';

  static const Set<String> all = {monthly, yearly};

  static String label(String productId) => switch (productId) {
        monthly => 'VIP 月卡',
        yearly => 'VIP 年卡',
        _ => productId,
      };
}
