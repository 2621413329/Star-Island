import 'package:flutter/material.dart';

import '../../../core/constants/companion_roles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/companion_avatar.dart';

/// 双角色选择卡片（小星仔 / 小光宝）。
class CharacterRolePicker extends StatelessWidget {
  const CharacterRolePicker({
    super.key,
    required this.palette,
    required this.selectedRoleId,
    required this.onSelected,
    this.avatarSize = 152,
    this.enabled = true,
  });

  final MoodPalette palette;
  final String? selectedRoleId;
  final ValueChanged<String> onSelected;
  final double avatarSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < CompanionRoles.selectableRoleIds.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: CharacterRoleOptionCard(
              roleId: CompanionRoles.selectableRoleIds[i],
              characterName:
                  CompanionRoles.nameFor(CompanionRoles.selectableRoleIds[i]),
              selected:
                  selectedRoleId == CompanionRoles.selectableRoleIds[i],
              palette: palette,
              avatarSize: avatarSize,
              onTap: enabled
                  ? () => onSelected(CompanionRoles.selectableRoleIds[i])
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class CharacterRoleOptionCard extends StatelessWidget {
  const CharacterRoleOptionCard({
    super.key,
    required this.roleId,
    required this.characterName,
    required this.selected,
    required this.palette,
    required this.avatarSize,
    this.onTap,
  });

  final String roleId;
  final String characterName;
  final bool selected;
  final MoodPalette palette;
  final double avatarSize;
  final VoidCallback? onTap;

  static const _previewStyle = 'mindscape';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.primaryContainer : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? palette.accent
                : palette.accent.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionAvatar(
              style: _previewStyle,
              gender: CompanionRoles.renderKey(roleId),
              scene: 'stargaze',
              expression: 'happy',
              size: avatarSize,
              palette: palette,
            ),
            const SizedBox(height: 12),
            Text(
              characterName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: selected ? palette.accent : const Color(0xFF5D4E42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
