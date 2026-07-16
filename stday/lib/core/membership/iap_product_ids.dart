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
            priceCny: 12,
          ),
        quarterly => const VipPlanUi(
            title: '季卡',
            displayTitle: '星屿会员 · 季卡',
            periodShort: '3 个月',
            periodLabel: '订阅时长：3 个月，自动续费',
            subtitle: '自动续费，每 3 个月续订',
            badge: '限时优惠',
            priceCny: 28,
          ),
        yearly => const VipPlanUi(
            title: '年卡',
            displayTitle: '星屿会员 · 年卡',
            periodShort: '12 个月',
            periodLabel: '订阅时长：12 个月，自动续费',
            subtitle: '自动续费，每年续订',
            badge: '推荐',
            priceCny: 98,
          ),
        _ => VipPlanUi(
            title: label(productId),
            displayTitle: label(productId),
            periodShort: '订阅',
            periodLabel: '自动续费订阅',
            subtitle: 'VIP 套餐',
          ),
      };

  /// 套餐价格统一按人民币展示（与后台 member_products 一致）。
  ///
  /// 已知套餐优先使用产品标价（¥），避免沙盒/外区 Apple ID 把美元价直接显示给用户。
  static String displayPriceCny({
    required String productId,
    double? storeRawPrice,
    String? storeCurrencyCode,
    String? storePriceLabel,
  }) {
    final plan = IapProductIds.plan(productId);
    if (plan.priceCny != null) {
      return formatCny(plan.priceCny!);
    }

    final code = (storeCurrencyCode ?? '').toUpperCase();
    if ((code == 'CNY' || code == 'RMB') && storeRawPrice != null) {
      return formatCny(storeRawPrice);
    }
    if ((code == 'CNY' || code == 'RMB') &&
        storePriceLabel != null &&
        storePriceLabel.trim().isNotEmpty) {
      return _normalizeCnyLabel(storePriceLabel);
    }
    // 非人民币商店价不直接展示，避免出现 US$ 等外币文案。
    return '价格待定';
  }

  /// 套餐卡片用：`¥12`，并附周期短后缀。
  static String displayPriceCnyWithPeriod({
    required String productId,
    double? storeRawPrice,
    String? storeCurrencyCode,
    String? storePriceLabel,
  }) {
    final price = displayPriceCny(
      productId: productId,
      storeRawPrice: storeRawPrice,
      storeCurrencyCode: storeCurrencyCode,
      storePriceLabel: storePriceLabel,
    );
    if (price == '价格待定') return price;
    final suffix = switch (productId) {
      monthly => '/月',
      quarterly => '/季',
      yearly => '/年',
      _ => '',
    };
    return '$price$suffix';
  }

  static String formatCny(num amount) {
    final value = amount.toDouble();
    if (value == value.roundToDouble()) {
      return '¥${value.toInt()}';
    }
    return '¥${value.toStringAsFixed(2)}';
  }

  static String _normalizeCnyLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('¥') || trimmed.contains('￥')) {
      return trimmed.replaceAll('￥', '¥');
    }
    final digits = RegExp(r'[\d.]+').firstMatch(trimmed)?.group(0);
    if (digits != null) {
      final parsed = double.tryParse(digits);
      if (parsed != null) return formatCny(parsed);
    }
    return '¥$trimmed';
  }
}

class VipPlanUi {
  const VipPlanUi({
    required this.title,
    required this.displayTitle,
    required this.periodShort,
    required this.periodLabel,
    required this.subtitle,
    this.badge,
    this.priceCny,
  });

  final String title;
  final String displayTitle;
  final String periodShort;
  final String periodLabel;
  final String subtitle;
  final String? badge;

  /// 人民币标价（元），用于套餐卡片展示。
  final double? priceCny;

  String get priceCnyLabel =>
      priceCny == null ? '价格待定' : IapProductIds.formatCny(priceCny!);
}
