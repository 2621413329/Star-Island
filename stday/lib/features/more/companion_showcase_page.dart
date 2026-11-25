import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/catalog.dart';
import '../../core/models/companion_spec.dart';
import '../../core/constants/companion_roles.dart';
import '../../core/models/user_companion.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/companion_base_expression.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/user_companion_view.dart';
import '../../providers/app_providers.dart';
import '../../providers/member_provider.dart';
import '../onboarding/widgets/character_role_picker.dart';

class CompanionShowcasePage extends ConsumerStatefulWidget {
  const CompanionShowcasePage({super.key});

  @override
  ConsumerState<CompanionShowcasePage> createState() =>
      _CompanionShowcasePageState();
}

class _CompanionShowcasePageState extends ConsumerState<CompanionShowcasePage> {
  late final PageController _moodPageController;
  int _moodIndex = 0;
  bool _changingRole = false;
  String? _previewRoleId;
  bool _savingRole = false;

  @override
  void initState() {
    super.initState();
    _moodPageController = PageController();
  }

  @override
  void dispose() {
    _moodPageController.dispose();
    super.dispose();
  }

  void _startRoleChange(String? currentRoleId) {
    setState(() {
      _changingRole = true;
      _previewRoleId = currentRoleId ?? CompanionRoles.defaultRoleId;
    });
  }

  void _cancelRoleChange() {
    setState(() {
      _changingRole = false;
      _previewRoleId = null;
    });
  }

  Future<void> _confirmRoleChange() async {
    final roleId = _previewRoleId;
    if (roleId == null || _savingRole) return;
    setState(() => _savingRole = true);
    try {
      await ref.read(profileProvider.notifier).updateCompanionRole(roleId);
      if (!mounted) return;
      setState(() {
        _changingRole = false;
        _previewRoleId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已更换为 ${CompanionRoles.nameFor(roleId)}'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _savingRole = false);
    }
  }

  void _handleBack() {
    if (_changingRole) {
      _cancelRoleChange();
    }
    context.pop();
  }

  CompanionStoryContext _storyForMood(MoodOption mood) {
    return CompanionStoryContext(
      spec: CompanionSpec(
        expression: companionBaseExpressionFromMoodId(mood.id),
        prop: 'none',
        animationType: 'wave',
        tint: mood.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final companion = ref.watch(userCompanionProvider);
    final isVip = ref.watch(isVipProvider);
    final currentMood = moods[_moodIndex];
    final displayCompanion = _changingRole && _previewRoleId != null
        ? companion.copyWith(companionRoleId: _previewRoleId)
        : companion;
    final companionName = CompanionRoles.nameFor(companion.resolvedRoleId);

    return PopScope(
      canPop: !_changingRole,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _changingRole) {
          _cancelRoleChange();
          context.pop();
        }
      },
      child: Scaffold(
        body: IslandScaffold(
          palette: palette,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _handleBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: const Color(0xFF5D4E44),
                      ),
                      Text(
                        '成长伙伴$companionName',
                        style: appTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D3229),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 280,
                                  child: PageView.builder(
                                    controller: _moodPageController,
                                    itemCount: moods.length,
                                    onPageChanged: (index) =>
                                        setState(() => _moodIndex = index),
                                    itemBuilder: (context, index) {
                                      final mood = moods[index];
                                      return Center(
                                        child: UserCompanionView(
                                          companion: displayCompanion,
                                          story: _storyForMood(mood),
                                          size: 220,
                                          palette: palette,
                                          showAura: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  currentMood.label,
                                  style: appTextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: currentMood.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < moods.length; i++)
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        width: i == _moodIndex ? 18 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: i == _moodIndex
                                              ? currentMood.color
                                              : currentMood.color
                                                  .withValues(alpha: 0.28),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '左右滑动，看看不同心情下的$companionName',
                                  style: appTextStyle(
                                    fontSize: 12,
                                    color:
                                        palette.primary.withValues(alpha: 0.55),
                                  ),
                                ),
                                if (!_changingRole) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    CompanionRoles.taglineFor(
                                      companion.resolvedRoleId,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: appTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: palette.primary
                                          .withValues(alpha: 0.78),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    CompanionRoles.descriptionFor(
                                          companion.resolvedRoleId,
                                        ) ??
                                        '',
                                    textAlign: TextAlign.left,
                                    style: appTextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: palette.primary
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (!_changingRole)
                                  TextButton.icon(
                                    onPressed: () => _startRoleChange(
                                      companion.resolvedRoleId,
                                    ),
                                    icon: Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 18,
                                      color: palette.accent,
                                    ),
                                    label: Text(
                                      '更换角色',
                                      style: appTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: palette.accent,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      backgroundColor:
                                          palette.card.withValues(alpha: 0.85),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: palette.accent
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Text(
                                    '预览新角色',
                                    style: appTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: palette.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CharacterRolePicker(
                                    palette: palette,
                                    selectedRoleId: _previewRoleId,
                                    avatarSize: 108,
                                    enabled: !_savingRole,
                                    isVip: isVip,
                                    showActionPill: false,
                                    onLockedRoleTap: (_) =>
                                        context.push('/more/membership'),
                                    onSelected: (roleId) =>
                                        setState(() => _previewRoleId = roleId),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _savingRole
                                              ? null
                                              : _cancelRoleChange,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF8C7B6B),
                                            side: BorderSide(
                                              color: palette.accent
                                                  .withValues(alpha: 0.3),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text('取消'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: _savingRole ||
                                                  _previewRoleId == null ||
                                                  _previewRoleId ==
                                                      companion.resolvedRoleId
                                              ? null
                                              : _confirmRoleChange,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: palette.accent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _savingRole
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text('选取'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
