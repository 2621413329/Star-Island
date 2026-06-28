import 'dart:async';

import 'package:flutter/material.dart';

import '../core/growth/level_unlock_celebration.dart';
import '../core/growth/growth_system.dart';
import '../core/growth/level_unlock_preview.dart';
import '../core/storage/daily_level_unlock_store.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';

enum GrowthRewardKind { daily, streak, levelUp }

bool _celebrationInFlight = false;

class GrowthRewardPayload {
  const GrowthRewardPayload({
    required this.kind,
    this.xp = 0,
    this.headline = '',
    this.body = '',
    this.subline = '',
  });

  final GrowthRewardKind kind;
  final int xp;
  final String headline;
  final String body;
  final String subline;
}

/// 成长值 +10 等轻量反馈：岛屿发光 + 浮现数值，约 2 秒（非全屏 Dialog）。
class GrowthValueOverlay {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required int xp,
    String headline = '🌱 今天的小岛记住了这一刻',
  }) {
    dismiss();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _GrowthValueOverlayWidget(
        xp: xp,
        headline: headline,
        onDismiss: () {
          if (entry.mounted) entry.remove();
          _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 2), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _GrowthValueOverlayWidget extends StatefulWidget {
  const _GrowthValueOverlayWidget({
    required this.xp,
    required this.headline,
    required this.onDismiss,
  });

  final int xp;
  final String headline;
  final VoidCallback onDismiss;

  @override
  State<_GrowthValueOverlayWidget> createState() =>
      _GrowthValueOverlayWidgetState();
}

class _GrowthValueOverlayWidgetState extends State<_GrowthValueOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _close() {
    widget.onDismiss();
    GrowthValueOverlay.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final glow = CurvedAnimation(
        parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    final xpAnim = CurvedAnimation(
        parent: _c,
        curve: const Interval(0.12, 0.55, curve: Curves.easeOutCubic));
    final textAnim = CurvedAnimation(
        parent: _c, curve: const Interval(0.35, 0.75, curve: Curves.easeOut));
    final fadeOut = CurvedAnimation(
        parent: _c, curve: const Interval(0.78, 1.0, curve: Curves.easeIn));

    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(fadeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(glow),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        palette.glow.withValues(alpha: 0.42),
                        palette.glow.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(fadeOut),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: xpAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(xpAnim),
                      child: ScaleTransition(
                        scale:
                            Tween<double>(begin: 0.6, end: 1).animate(xpAnim),
                        child: Text(
                          '+${widget.xp}',
                          style: appTextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: textAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(textAnim),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          widget.headline,
                          textAlign: TextAlign.center,
                          style: appTextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5D4E44),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 连续记录 / 升级等仪式感反馈（非 Toast，约 2 秒自动关闭）。
class GrowthRewardDialog {
  static Future<void> show(
    BuildContext context, {
    required GrowthRewardPayload payload,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (ctx) => _GrowthRewardDialogBody(payload: payload),
    );
  }
}

class _GrowthRewardDialogBody extends StatefulWidget {
  const _GrowthRewardDialogBody({required this.payload});

  final GrowthRewardPayload payload;

  @override
  State<_GrowthRewardDialogBody> createState() =>
      _GrowthRewardDialogBodyState();
}

class _GrowthRewardDialogBodyState extends State<_GrowthRewardDialogBody> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _autoClose = Timer(const Duration(seconds: 2), _pop);
  }

  void _pop() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    return GestureDetector(
      onTap: _pop,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.headline,
              textAlign: TextAlign.center,
              style: appTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3D3229),
              ),
            ),
            if (p.body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                p.body,
                textAlign: TextAlign.center,
                style: appTextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: const Color(0xFF5D4E44),
                ),
              ),
            ],
            if (p.subline.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                p.subline,
                textAlign: TextAlign.center,
                style: appTextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: const Color(0xFF8C7B6B),
                ),
              ),
            ],
            if (p.xp > 0) ...[
              const SizedBox(height: 14),
              Text(
                '成长值 +${p.xp}',
                style: appTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: defaultPalette.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 升级庆祝：先仪式感文案，再解锁预览（支持多项左右滑动）。
Future<void> showLevelUnlockCelebration(
  BuildContext context, {
  required GrowthSummary summary,
  required int fromLevel,
  DailyLevelUnlockStore? store,
  String? userId,
  bool markAck = true,
}) async {
  if (_celebrationInFlight || !context.mounted || summary.isGuest) return;
  if (summary.level <= fromLevel) return;

  _celebrationInFlight = true;
  try {
    final items = collectNewUnlockItems(
      fromLevel: fromLevel,
      toLevel: summary.level,
    );

    await GrowthRewardDialog.show(
      context,
      payload: GrowthRewardPayload(
        kind: GrowthRewardKind.levelUp,
        headline: '✨ 恭喜升级',
        body: GrowthSystem.levelDisplayLabel(summary),
        subline: levelUnlockRangeSummary(
          fromLevel: fromLevel,
          toLevel: summary.level,
        ),
      ),
    );

    if (!context.mounted) return;

    if (items.isNotEmpty) {
      await showLevelUnlockPreviewDialog(
        context,
        level: summary.level,
        unlocked: true,
        items: items,
      );
    }

    if (markAck) {
      await (store ?? DailyLevelUnlockStore())
          .markAckLevel(userId, summary.level);
    }
  } finally {
    _celebrationInFlight = false;
  }
}

