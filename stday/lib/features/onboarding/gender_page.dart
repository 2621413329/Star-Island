import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/layout/app_layout.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import 'widgets/character_role_picker.dart';

class GenderPage extends ConsumerStatefulWidget {
  const GenderPage({super.key});

  @override
  ConsumerState<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends ConsumerState<GenderPage> {
  String? _selected;
  bool _loading = false;

  Future<void> _enterApp() async {
    if (_selected == null || _loading) return;
    if (!ref.read(authProvider).isLoggedIn) {
      context.go('/auth');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).updateCompanionRole(_selected!);
      if (!mounted) return;
      context.go('/records');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.pageHorizontal,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '请选择你想要登岛的角色',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '选择你喜欢的小星，一起开启成长之旅',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8C7B6B)),
                      ),
                      const SizedBox(height: 24),
                      CharacterRolePicker(
                        palette: palette,
                        selectedRoleId: _selected,
                        enabled: !_loading,
                        onSelected: (roleId) =>
                            setState(() => _selected = roleId),
                      ),
                      const SizedBox(height: 28),
                      IslandPrimaryAction(
                        label: '进入成长小岛',
                        palette: palette,
                        loading: _loading,
                        onPressed:
                            _selected == null || _loading ? null : _enterApp,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
