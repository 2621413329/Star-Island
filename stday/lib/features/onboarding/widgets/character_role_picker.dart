import 'package:flutter/material.dart';

import '../../../core/constants/companion_roles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../design_system/companion_avatar.dart';

/// 角色选择卡片：支持免费角色与会员专属角色左右滑动预览。
class CharacterRolePicker extends StatefulWidget {
  const CharacterRolePicker({
    super.key,
    required this.palette,
    required this.selectedRoleId,
    required this.onSelected,
    this.avatarSize = 152,
    this.enabled = true,
    this.isVip = false,
    this.showActionPill = true,
    this.onLockedRoleTap,
  });

  final MoodPalette palette;
  final String? selectedRoleId;
  final ValueChanged<String> onSelected;
  final double avatarSize;
  final bool enabled;
  final bool isVip;
  final bool showActionPill;
  final ValueChanged<String>? onLockedRoleTap;

  @override
  State<CharacterRolePicker> createState() => _CharacterRolePickerState();
}

class _CharacterRolePickerState extends State<CharacterRolePicker> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final selectedIndex = CompanionRoles.selectableRoleIds.indexOf(
      widget.selectedRoleId ?? CompanionRoles.defaultRoleId,
    );
    _page = selectedIndex < 0 ? 0 : selectedIndex;
    _controller = PageController(
      initialPage: _page,
      viewportFraction: 0.78,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = CompanionRoles.selectableRoleIds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.avatarSize + 275,
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: roles.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final roleId = roles[index];
              final locked = CompanionRoles.isPremium(roleId) && !widget.isVip;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: CharacterRoleOptionCard(
                  roleId: roleId,
                  characterName: CompanionRoles.nameFor(roleId),
                  selected: widget.selectedRoleId == roleId,
                  palette: widget.palette,
                  avatarSize: widget.avatarSize,
                  locked: locked,
                  showActionPill: widget.showActionPill || locked,
                  enabled: widget.enabled,
                  onTap: locked
                      ? () => widget.onLockedRoleTap?.call(roleId)
                      : widget.enabled
                          ? () => widget.onSelected(roleId)
                          : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < roles.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _page == i
                      ? widget.palette.accent
                      : widget.palette.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleActionPill extends StatelessWidget {
  const _RoleActionPill({
    required this.label,
    required this.palette,
    required this.locked,
    required this.selected,
  });

  final String label;
  final MoodPalette palette;
  final bool locked;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? const Color(0xFF9A7A43)
        : selected
            ? palette.accent
            : palette.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: locked ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
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
    required this.locked,
    required this.showActionPill,
    required this.enabled,
    this.onTap,
  });

  final String roleId;
  final String characterName;
  final bool selected;
  final MoodPalette palette;
  final double avatarSize;
  final bool locked;
  final bool showActionPill;
  final bool enabled;
  final VoidCallback? onTap;

  static const _previewStyle = 'mindscape';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? palette.primaryContainer
              : locked
                  ? palette.card.withValues(alpha: 0.74)
                  : palette.card,
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
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: locked ? 0.72 : 1,
                  child: CompanionAvatar(
                    style: _previewStyle,
                    gender: CompanionRoles.renderKey(roleId),
                    scene: 'stargaze',
                    expression: 'happy',
                    size: avatarSize,
                    palette: palette,
                  ),
                ),
                if (locked)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFD2B56B).withValues(alpha: 0.7),
                        ),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('🔒', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
              ],
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
            const SizedBox(height: 4),
            Text(
              CompanionRoles.taglineFor(roleId),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: selected
                    ? palette.accent.withValues(alpha: 0.78)
                    : const Color(0xFF8C7B6B),
              ),
            ),
            if (CompanionRoles.descriptionFor(roleId) case final description?)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 132),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      description,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: const Color(0xFF6F6258)
                            .withValues(alpha: locked ? 0.72 : 0.92),
                      ),
                    ),
                  ),
                ),
              ),
            if (showActionPill) ...[
              const SizedBox(height: 12),
              _RoleActionPill(
                label: locked
                    ? '🔒 星屿会员专属'
                    : selected
                        ? '已选取'
                        : '选取',
                palette: palette,
                locked: locked,
                selected: selected,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
