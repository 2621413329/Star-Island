import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/companion_prop_labels.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/mood_theme.dart';
import 'companion_showcase_page.dart';

String formatPropFirstEarnedAt(DateTime time) {
  return DateFormat('yyyy年M月d日 HH:mm', 'zh_CN').format(time.toLocal());
}

String companionPropDisplayTitle({
  required String prop,
  required String assetPath,
  String? storedLabel,
}) {
  return CompanionPropLabels.resolve(
    prop: prop,
    assetPath: assetPath,
    storedLabel: storedLabel,
  );
}

Future<void> showCompanionPropBadgeDetail(
  BuildContext context, {
  required CollectedCompanionProp prop,
  required MoodPalette palette,
  String? heroTag,
}) {
  final title = prop.displayTitle;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭配饰详情',
    barrierColor: Colors.black.withValues(alpha: 0.52),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Material(
              color: Colors.transparent,
              child: _CompanionPropBadgeCard(
                prop: prop,
                palette: palette,
                title: title,
                heroTag: heroTag,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

class _CompanionPropBadgeCard extends StatelessWidget {
  const _CompanionPropBadgeCard({
    required this.prop,
    required this.palette,
    required this.title,
    required this.onClose,
    this.heroTag,
  });

  final CollectedCompanionProp prop;
  final MoodPalette palette;
  final String title;
  final VoidCallback onClose;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            palette.card.withValues(alpha: 0.96),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgeMedallion(
            assetPath: prop.assetPath,
            palette: palette,
            heroTag: heroTag,
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: appTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3D3229),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '首次获得',
            style: appTextStyle(
              fontSize: 12,
              color: palette.primary.withValues(alpha: 0.55),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatPropFirstEarnedAt(prop.firstEarnedAt),
            style: appTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '来自一次成长日常',
            style: appTextStyle(
              fontSize: 12,
              color: palette.primary.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(
              foregroundColor: palette.primary.withValues(alpha: 0.72),
            ),
            child: const Text('知道了'),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {},
      child: badge,
    );
  }
}

class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({
    required this.assetPath,
    required this.palette,
    this.heroTag,
  });

  final String assetPath;
  final MoodPalette palette;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final medallion = Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.accent.withValues(alpha: 0.95),
            palette.primary.withValues(alpha: 0.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: palette.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );

    if (heroTag == null) return medallion;
    return Hero(tag: heroTag!, child: medallion);
  }
}
