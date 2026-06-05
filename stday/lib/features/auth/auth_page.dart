import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/growth_island_rules_sheet.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.length < 3 || password.length < 6) {
      setState(() => _error = '用户名至少3位，密码至少6位');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(appRepositoryProvider).login(
            username: username,
            password: password,
          );
      await ref.read(authProvider.notifier).setToken(token);
      await ref.read(profileProvider.notifier).refresh();
      if (!mounted) return;
      await showGrowthIslandRulesIfNeeded(context);
      if (!mounted) return;
      _routeAfterAuth();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _routeAfterAuth() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile == null || profile.gender == null) {
      context.go('/onboarding/gender');
      return;
    }
    context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/welcome');
                                    }
                                  },
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: palette.accent,
                            ),
                            tooltip: '返回',
                          ),
                        ),
                        const SizedBox(height: 4),
                        IslandGlassCard(
                          palette: palette,
                          child: Column(
                            children: [
                              CompanionAvatar(
                                style: 'chibi',
                                size: 90,
                                palette: palette,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '登录',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _userCtrl,
                          decoration: InputDecoration(
                            labelText: '用户名',
                            hintText: '登录账号，非昵称',
                            filled: true,
                            fillColor: palette.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: '密码',
                            filled: true,
                            fillColor: palette.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!_loading) _submit();
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const Spacer(),
                        IslandPrimaryAction(
                          label: '登录',
                          loading: _loading,
                          palette: palette,
                          onPressed: _loading ? null : _submit,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                              _loading ? null : () => context.go('/auth/register'),
                          child: const Text('还没有账号？去注册'),
                        ),
                      ],
                    ),
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
