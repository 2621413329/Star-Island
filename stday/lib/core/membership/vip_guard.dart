import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 未开通 VIP 时弹出提示。
Future<void> showVipRequiredDialog(
  BuildContext context, {
  String title = 'VIP 专属功能',
  String message = '开通 VIP 后即可使用此功能',
  bool showUpgradeAction = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('知道了'),
        ),
        if (showUpgradeAction)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.push('/more/membership');
            },
            child: const Text('开通 VIP'),
          ),
      ],
    ),
  );
}

/// 跳转到 VIP 会员页。
void openMembershipPage(BuildContext context) {
  context.push('/more/membership');
}

/// 非 VIP 时在内容上叠加蒙版。
class VipFeatureMask extends StatelessWidget {
  const VipFeatureMask({
    super.key,
    required this.locked,
    required this.child,
    this.message = '开通 VIP 查看完整内容',
    this.onUnlockTap,
  });

  final bool locked;
  final Widget child;
  final String message;
  final VoidCallback? onUnlockTap;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return Stack(
      children: [
        IgnorePointer(child: child),
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            child: InkWell(
              onTap: onUnlockTap ??
                  () => openMembershipPage(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
