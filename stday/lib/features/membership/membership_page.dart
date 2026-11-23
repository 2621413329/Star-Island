import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/api/api_client.dart';
import '../../core/audio/app_audio_assets.dart';
import '../../core/legal/legal_documents.dart';
import '../../core/membership/iap_product_ids.dart';
import '../../core/theme/mood_theme.dart';
import '../../core/utils/api_datetime.dart';
import '../../data/models/member_models.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/legal_agreement.dart'
    show openLegalDocument;
import '../../providers/app_audio_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/iap_provider.dart';
import '../../providers/member_provider.dart';
import '../more/widgets/more_subpage_header.dart';

/// VIP 会员中心：App Store 订阅开通，页底保留激活码。
class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});

  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  final _codeCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  String _selectedProductId = IapProductIds.yearly;
  bool _purchasePending = false;
  bool _wasVipBeforePurchase = false;

  static const _benefitsSummary =
      '开通后可使用：成长统计、AI 心情总结、照片与语音记录、更多伙伴对话、更多小岛数量等屿之迹会员功能。';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberProvider.notifier).ensureFresh();
      ref.read(iapCatalogProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '请输入激活码');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(memberProvider.notifier).redeemActivationCode(code);
      if (!mounted) return;
      _codeCtrl.clear();
      unawaited(
        ref.read(appAudioControllerProvider).playSfx(AppSfx.vipSuccess),
      );
      AppFeedback.showWeak(context, '会员已开通');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _buy(ProductDetails product) async {
    _wasVipBeforePurchase = ref.read(isVipProvider);
    _purchasePending = true;
    await ref.read(iapCatalogProvider.notifier).buy(product);
  }

  Future<void> _restore() async {
    final ok = await ref.read(iapCatalogProvider.notifier).restore();
    if (!mounted || !ok) return;
    unawaited(
      ref.read(appAudioControllerProvider).playSfx(AppSfx.vipSuccess),
    );
    AppFeedback.showWeak(context, '已恢复购买');
  }

  String _vipStatusText(MemberMeModel? member) {
    if (member == null) return '加载中…';
    if (!member.isVip) return '尚未开通屿之迹会员';
    final type = switch (member.membershipType) {
      'monthly' => '月卡',
      'quarterly' => '季卡',
      'yearly' => '年卡',
      'lifetime' => '终身',
      _ => '会员',
    };
    if (member.expireTime == null) return '已开通$type（永久有效）';
    final label = formatMembershipExpireDate(member.expireTime!);
    return '已开通$type，有效期至 $label';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(iapCatalogProvider, (previous, next) {
      if (!_purchasePending || next.purchasing) return;
      _purchasePending = false;
      if (next.error != null ||
          _wasVipBeforePurchase ||
          !ref.read(isVipProvider)) {
        return;
      }
      unawaited(
        ref.read(appAudioControllerProvider).playSfx(AppSfx.vipSuccess),
      );
      AppFeedback.showWeak(context, '会员已开通');
    });

    final palette = ref.watch(moodPaletteProvider);
    final member = ref.watch(memberProvider).valueOrNull;
    final isVip = ref.watch(isVipProvider);
    final iap = ref.watch(iapCatalogProvider);
    final selectedProduct = _findProduct(iap.products, _selectedProductId);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              const MoreSubpageHeader(title: '屿之迹会员'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isVip
                                      ? Icons.workspace_premium_rounded
                                      : Icons.lock_open_rounded,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isVip ? '屿之迹会员已开通' : '开通屿之迹会员',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: palette.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _vipStatusText(member),
                              style: TextStyle(
                                height: 1.5,
                                color: palette.primary.withValues(alpha: 0.78),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _benefitsSummary,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: palette.primary.withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SubscriptionPlanSelector(
                      palette: palette,
                      selectedProductId: _selectedProductId,
                      products: iap.products,
                      onSelected: (productId) {
                        setState(() => _selectedProductId = productId);
                      },
                    ),
                    const SizedBox(height: 12),
                    _PaymentActionCard(
                      palette: palette,
                      productId: _selectedProductId,
                      product: selectedProduct,
                      loading: iap.loading,
                      purchasing: iap.purchasing,
                      restoring: iap.restoring,
                      storeAvailable: iap.available,
                      storeError: iap.error,
                      onPay: _buy,
                      onRetry: () {
                        ref.read(iapCatalogProvider.notifier).loadProducts();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SubscriptionNoticeCard(palette: palette),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: (iap.purchasing || iap.restoring)
                            ? null
                            : _restore,
                        child: Text(iap.restoring ? '恢复中…' : '恢复购买'),
                      ),
                    ),
                    _LegalLinksRow(palette: palette),
                    const SizedBox(height: 16),
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '输入激活码开通',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '也可以输入有效激活码开通屿之迹会员。',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: palette.primary.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _codeCtrl,
                              enabled: !_submitting,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              enableSuggestions: false,
                              onSubmitted: (_) {
                                if (!_submitting) _redeem();
                              },
                              decoration: InputDecoration(
                                labelText: '激活码',
                                hintText: '请输入激活码',
                                filled: true,
                                fillColor: palette.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            IslandPrimaryAction(
                              label: _submitting ? '开通中…' : '立即开通',
                              palette: palette,
                              loading: _submitting,
                              onPressed: _submitting ? null : _redeem,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ProductDetails? _findProduct(List<ProductDetails> products, String productId) {
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
}

class _PaymentActionCard extends StatelessWidget {
  const _PaymentActionCard({
    required this.palette,
    required this.productId,
    required this.product,
    required this.loading,
    required this.purchasing,
    this.restoring = false,
    required this.storeAvailable,
    required this.onPay,
    required this.onRetry,
    this.storeError,
  });

  final MoodPalette palette;
  final String productId;
  final ProductDetails? product;
  final bool loading;
  final bool purchasing;
  final bool restoring;
  final bool storeAvailable;
  final String? storeError;
  final ValueChanged<ProductDetails> onPay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final plan = IapProductIds.plan(productId);
    final canPay = product != null && !loading && !purchasing && !restoring;
    final priceLabel = IapProductIds.displayPriceCnyWithPeriod(
      productId: productId,
      storeRawPrice: product?.rawPrice,
      storeCurrencyCode: product?.currencyCode,
      storePriceLabel: product?.price,
    );
    final hasError = storeError != null && storeError!.trim().isNotEmpty;

    String helperText;
    if (loading) {
      helperText = '正在从 App Store 加载订阅价格与套餐信息…';
    } else if (!storeAvailable) {
      helperText = '当前无法连接 App Store。请使用 iOS 真机，并确认已登录 Apple ID 后重试。';
    } else if (product == null) {
      helperText = '暂时无法获取该订阅商品。请检查网络后点「重新加载」，或稍后再试。';
    } else {
      helperText =
          '点击「立即开通」将调起 App Store 确认订阅。订阅会自动续费，可随时在 Apple ID 订阅设置中取消。';
    }

    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              IapProductIds.serviceName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.displayTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.periodLabel,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: palette.primary.withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              helperText,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: palette.primary.withValues(alpha: 0.58),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 10),
              Text(
                storeError!,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: IslandPrimaryAction(
                    label: purchasing
                        ? '开通处理中…'
                        : restoring
                            ? '恢复中…'
                            : '立即开通',
                    palette: palette,
                    onPressed: canPay ? () => onPay(product!) : null,
                  ),
                ),
                if ((product == null || hasError) && !loading) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('重新加载'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionNoticeCard extends StatelessWidget {
  const _SubscriptionNoticeCard({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: palette.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  '自动续费说明',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '付款将计入你的 Apple ID 账户。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '订阅会自动续费，除非在当前订阅期结束至少 24 小时前取消。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '续费费用会在当前订阅期结束前 24 小时内按所选套餐扣款。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '可随时在「设置」> Apple ID >「订阅」中管理或取消订阅。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '更换设备或重装后，可点击下方「恢复购买」同步已购买的会员权益。',
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionNoticeLine extends StatelessWidget {
  const _SubscriptionNoticeLine({
    required this.palette,
    required this.text,
  });

  final MoodPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '• $text',
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: palette.primary.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _LegalLinksRow extends StatelessWidget {
  const _LegalLinksRow({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: palette.accent,
      decoration: TextDecoration.underline,
      decorationColor: palette.accent,
    );

    return Column(
      children: [
        Text(
          '点击下方链接将在浏览器中打开',
          style: TextStyle(
            fontSize: 12,
            color: palette.primary.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => openLegalDocument(context, userAgreement),
              child: Text('Terms of Use / 用户协议', style: linkStyle),
            ),
            Text(
              '·',
              style: TextStyle(color: palette.primary.withValues(alpha: 0.45)),
            ),
            TextButton(
              onPressed: () => openLegalDocument(context, privacyPolicy),
              child: Text('Privacy Policy / 隐私政策', style: linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubscriptionPlanSelector extends StatelessWidget {
  const _SubscriptionPlanSelector({
    required this.palette,
    required this.selectedProductId,
    required this.products,
    required this.onSelected,
  });

  static const _productIds = [
    IapProductIds.monthly,
    IapProductIds.quarterly,
    IapProductIds.yearly,
  ];

  final MoodPalette palette;
  final String selectedProductId;
  final List<ProductDetails> products;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            for (final productId in _productIds) ...[
              Expanded(
                child: _SubscriptionPlanButton(
                  palette: palette,
                  productId: productId,
                  product: _findProduct(products, productId),
                  selected: selectedProductId == productId,
                  onTap: () => onSelected(productId),
                ),
              ),
              if (productId != _productIds.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPlanButton extends StatelessWidget {
  const _SubscriptionPlanButton({
    required this.palette,
    required this.productId,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final MoodPalette palette;
  final String productId;
  final ProductDetails? product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plan = IapProductIds.plan(productId);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? palette.accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? palette.accent
                : palette.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              plan.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? palette.accent : palette.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.periodShort,
              style: TextStyle(
                fontSize: 11,
                color: palette.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              IapProductIds.displayPriceCnyWithPeriod(
                productId: productId,
                storeRawPrice: product?.rawPrice,
                storeCurrencyCode: product?.currencyCode,
                storePriceLabel: product?.price,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.primary.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected ? '已选择' : '订阅',
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? palette.accent
                    : palette.primary.withValues(alpha: 0.52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
