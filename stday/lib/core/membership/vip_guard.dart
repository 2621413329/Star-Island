import 'dart:ui';

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
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.58,
                  child: child,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF8EE).withValues(alpha: 0.30),
                  const Color(0xFFFFF1DF).withValues(alpha: 0.76),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onUnlockTap ?? () => openMembershipPage(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFC86B).withValues(alpha: 0.42),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF7A5A2A).withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_open_rounded,
                            color: Color(0xFFE0A33A),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B5641),
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ) ??
                                const TextStyle(
                                  color: Color(0xFF6B5641),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '轻触开通后查看完整内容',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9B8064),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
