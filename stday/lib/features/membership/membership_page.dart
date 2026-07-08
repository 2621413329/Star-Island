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
  final _codeCtrl = TextEditingController();
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapCatalogProvider.notifier).ensureInitialized();
      ref.read(memberProvider.notifier).ensureFresh();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _redeeming = true);
    try {
      await ref.read(memberRepositoryProvider).redeemActivationCode(code);
      await ref.read(memberProvider.notifier).refresh(force: true);
      if (!mounted) return;
      AppFeedback.showWeak(context, '激活成功');
      _codeCtrl.clear();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
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
                    if (iap.loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (iap.products.isNotEmpty) ...[
                      Text(
                        '选择套餐',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...iap.products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProductTile(
                            palette: palette,
                            product: product,
                            busy: iap.purchasing,
                            onBuy: () => ref
                                .read(iapCatalogProvider.notifier)
                                .buy(product),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
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
                            : const Text('恢复购买'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '激活码兑换',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: '激活码',
                                hintText: '请输入激活码',
                              ),
                            ),
                            const SizedBox(height: 12),
                            IslandPrimaryAction(
                              label: _redeeming ? '兑换中…' : '兑换激活码',
                              palette: palette,
                              onPressed:
                                  _redeeming ? null : () => _redeemCode(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (iap.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        iap.error!,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.palette,
    required this.product,
    required this.busy,
    required this.onBuy,
  });

  final MoodPalette palette;
  final ProductDetails product;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      child: ListTile(
        title: Text(IapProductIds.label(product.id)),
        subtitle: Text(product.description),
        trailing: FilledButton(
          onPressed: busy ? null : onBuy,
          child: Text(product.price),
        ),
      ),
    );
  }
}
