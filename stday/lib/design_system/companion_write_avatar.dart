import 'package:flutter/material.dart';

import '../core/constants/companion_roles.dart';
import '../core/constants/companion_write_asset.dart';
import '../core/models/user_companion.dart';

/// 「记录今天的故事」卡片左侧角色图：按登岛角色展示 wright 立绘。
class CompanionWriteAvatar extends StatelessWidget {
  const CompanionWriteAvatar({
    super.key,
    required this.companion,
    this.size = 56,
    this.semanticLabel,
  });

  final UserCompanion companion;
  final double size;

  /// 默认可读名称；未传时使用角色显示名。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final roleId = companion.resolvedRoleId;
    final label =
        semanticLabel ?? '${CompanionRoles.nameFor(roleId)}写作形象';
    final assetPath = CompanionWriteAssets.assetPathFor(roleId);
    return Semantics(
      label: label,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            final fallback = CompanionWriteAssets.assetPathFor(
              CompanionRoles.defaultRoleId,
            );
            if (fallback == assetPath) return _placeholder(size);
            return Image.asset(
              fallback,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => _placeholder(size),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder(double side) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(side * 0.22),
      ),
      child: Icon(
        Icons.face_retouching_natural_outlined,
        size: side * 0.46,
        color: const Color(0xFF6EB8F7),
      ),
    );
  }
}
