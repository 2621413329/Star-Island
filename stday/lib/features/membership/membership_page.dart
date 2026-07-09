import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/membership/iap_product_ids.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/member_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/iap_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/app_providers.dart';
import '../more/widgets/more_subpage_header.dart';

/// VIP 会员中心：App Store 购买、恢复购买、激活码兑换。
class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});

  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  String _activationProductId = IapProductIds.yearly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapCatalogProvider.notifier).ensureInitialized();
      ref.read(memberProvider.notifier).ensureFresh();
    });
  }

  Future<void> _showRedeemCodeDialog() async {
    final plan = IapProductIds.plan(_activationProductId);
    final codeCtrl = TextEditingController();
    var redeeming = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('兑换${plan.title}激活码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: '激活码',
                    hintText: '请输入${plan.title}激活码',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '实际开通时长以激活码绑定的套餐为准。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    redeeming ? null : () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: redeeming
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('请输入${plan.title}激活码')),
                          );
                          return;
                        }
                        setDialogState(() => redeeming = true);
                        try {
                          await ref
                              .read(memberRepositoryProvider)
                              .redeemActivationCode(code);
                          await ref
                              .read(memberProvider.notifier)
                              .refresh(force: true);
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);
                          AppFeedback.showWeak(context, '激活成功');
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => redeeming = false);
                          }
                        }
                      },
                child: redeeming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('确认兑换'),
              ),
            ],
          ),
        );
      },
    );
    codeCtrl.dispose();
  }

  String _vipStatusText(MemberMeModel? member) {
    if (member == null) return '加载中…';
    if (!member.isVip) return '未开通 VIP';
    final type = switch (member.membershipType) {
      'monthly' => '月卡',
      'quarterly' => '季卡',
      'yearly' => '年卡',
      'lifetime' => '终身',
      _ => 'VIP',
    };
    if (member.expireTime == null) return '已开通 $type（永久有效）';
    final local = member.expireTime!.toLocal();
    final label = DateFormat('yyyy年M月d日', 'zh_CN').format(local);
    return '已开通 $type，有效期至 $label';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final member = ref.watch(memberProvider).valueOrNull;
    final isVip = ref.watch(isVipProvider);
    final iap = ref.watch(iapCatalogProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              const MoreSubpageHeader(title: 'VIP 会员'),
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
                                  isVip ? 'VIP 已激活' : '开通 VIP',
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
                              '解锁成长统计、AI 心情总结、照片语音记录、更多小人对话与小岛数量等完整功能。',
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
                    if (!iap.available && !iap.loading) ...[
                      IslandGlassCard(
                        palette: palette,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'App Store 内购仅支持 iOS 真机。'
                            '你也可以在下方输入激活码开通 VIP。',
                            style: TextStyle(
                              height: 1.5,
                              color: palette.primary.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      '激活套餐',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActivationPlanSelector(
                      palette: palette,
                      selectedProductId: _activationProductId,
                      onSelected: (productId) {
                        setState(() => _activationProductId = productId);
                      },
                    ),
                    const SizedBox(height: 10),
                    _PaymentActionCard(
                      palette: palette,
                      productId: _activationProductId,
                      product: _findProduct(iap.products, _activationProductId),
                      loading: iap.loading,
                      purchasing: iap.purchasing,
                      storeError: iap.error,
                      onPay: (product) =>
                          ref.read(iapCatalogProvider.notifier).buy(product),
                      onRetry: () =>
                          ref.read(iapCatalogProvider.notifier).loadProducts(),
                    ),
                    const SizedBox(height: 12),
                    _SubscriptionNoticeCard(palette: palette),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: iap.restoring
                            ? null
                            : () async {
                                final ok = await ref
                                    .read(iapCatalogProvider.notifier)
                                    .restore();
                                if (!context.mounted) return;
                                if (ok) {
                                  AppFeedback.showWeak(context, '购买已恢复');
                                }
                              },
                        child: iap.restoring
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('恢复购买 / Restore Purchases'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _showRedeemCodeDialog,
                      icon: const Icon(Icons.confirmation_number_rounded),
                      label: const Text('激活码兑换'),
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
    required this.onPay,
    required this.onRetry,
    this.storeError,
  });

  final MoodPalette palette;
  final String productId;
  final ProductDetails? product;
  final bool loading;
  final bool purchasing;
  final String? storeError;
  final ValueChanged<ProductDetails> onPay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final plan = IapProductIds.plan(productId);
    final canPay = product != null && !loading && !purchasing;

    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '当前套餐：${plan.title}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                ),
                Text(
                  product?.price ?? '¥${plan.promoPrice}',
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
              product == null
                  ? 'App Store 商品暂未准备好，请稍后重试或使用激活码开通。'
                  : '点击确认支付后，将调起 App Store 内购确认。订阅会自动续费，可随时在 Apple ID 订阅设置中取消。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: palette.primary.withValues(alpha: 0.58),
              ),
            ),
            if (storeError != null) ...[
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
                    label: purchasing ? '支付处理中…' : '确认支付',
                    palette: palette,
                    onPressed: canPay ? () => onPay(product!) : null,
                  ),
                ),
                if (product == null && !loading) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('重新获取'),
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
                  '订阅说明',
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
              text: '购买确认后将通过你的 Apple ID 扣款。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '订阅会自动续费，除非在当前订阅期结束至少 24 小时前取消。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '续费费用会在订阅期结束前 24 小时内按所选套餐扣款。',
            ),
            _SubscriptionNoticeLine(
              palette: palette,
              text: '你可以随时在 iPhone「设置」> Apple ID >「订阅」中管理或取消订阅。',
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

class _ActivationPlanSelector extends StatelessWidget {
  const _ActivationPlanSelector({
    required this.palette,
    required this.selectedProductId,
    required this.onSelected,
  });

  static const _products = [
    IapProductIds.monthly,
    IapProductIds.quarterly,
    IapProductIds.yearly,
  ];

  final MoodPalette palette;
  final String selectedProductId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            for (final productId in _products) ...[
              Expanded(
                child: _ActivationPlanButton(
                  palette: palette,
                  productId: productId,
                  selected: selectedProductId == productId,
                  onTap: () => onSelected(productId),
                ),
              ),
              if (productId != _products.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivationPlanButton extends StatelessWidget {
  const _ActivationPlanButton({
    required this.palette,
    required this.productId,
    required this.selected,
    required this.onTap,
  });

  final MoodPalette palette;
  final String productId;
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
              '¥${plan.promoPrice}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.primary.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected ? '已选择' : '选择激活',
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
