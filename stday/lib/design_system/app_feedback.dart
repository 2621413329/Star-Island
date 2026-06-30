import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_fonts.dart';

/// 应用内反馈：弱提示（同步/更新）与强提示（成长里程碑）。
abstract final class AppFeedback {
  static OverlayEntry? _weakEntry;
  static Timer? _weakDismissTimer;
  static DateTime? _lastWeakAt;

  static const _weakCooldown = Duration(milliseconds: 2500);
  static const _weakVisible = Duration(milliseconds: 1800);

  /// 弱提示：顶部轻量 Toast，自动消失；冷却期内多次同步只展示一次。
  static void showWeak(BuildContext context, String message) {
    final now = DateTime.now();
    if (_lastWeakAt != null &&
        now.difference(_lastWeakAt!) < _weakCooldown) {
      return;
    }
    _lastWeakAt = now;
    _dismissWeak();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _WeakToastBanner(message: message),
    );
    _weakEntry = entry;
    overlay.insert(entry);
    _weakDismissTimer = Timer(_weakVisible, () {
      if (entry.mounted) entry.remove();
      if (_weakEntry == entry) _weakEntry = null;
    });
  }

  /// 强提示：顶部横幅，搭配成长元素，适合升级/连续打卡等正向反馈。
  static void showStrong(
    BuildContext context, {
    required String message,
    String? subtitle,
    Duration visibleFor = const Duration(milliseconds: 2600),
  }) {
    _dismissWeak();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _StrongGrowthBanner(
        message: message,
        subtitle: subtitle,
      ),
    );
    overlay.insert(entry);
    Timer(visibleFor, () {
      if (entry.mounted) entry.remove();
    });
  }

  static void _dismissWeak() {
    _weakDismissTimer?.cancel();
    _weakDismissTimer = null;
    _weakEntry?.remove();
    _weakEntry = null;
  }
}

class _WeakToastBanner extends StatefulWidget {
  const _WeakToastBanner({required this.message});

  final String message;

  @override
  State<_WeakToastBanner> createState() => _WeakToastBannerState();
}

class _WeakToastBannerState extends State<_WeakToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 10,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _controller,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8ECAE6).withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: appTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D4E44),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrongGrowthBanner extends StatefulWidget {
  const _StrongGrowthBanner({
    required this.message,
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  State<_StrongGrowthBanner> createState() => _StrongGrowthBannerState();
}

class _StrongGrowthBannerState extends State<_StrongGrowthBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: _controller,
          child: Material(
            elevation: 6,
            color: const Color(0xFFFFF6EA),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🌱', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message,
                            style: appTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3D3229),
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: appTextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: const Color(0xFF8C7B6B),
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
          ),
        ),
      ),
    );
  }
}
