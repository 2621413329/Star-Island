import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/companion_avatar.dart';
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
      final result = await ref.read(appRepositoryProvider).authEntry(username, password);
      await ref.read(authProvider.notifier).setToken(result.accessToken);
      await ref.read(profileProvider.notifier).refresh();
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
    if (profile.companionStyle == null || !profile.onboardingCompleted) {
      context.go('/onboarding/companion');
      return;
    }
    context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                IslandGlassCard(
                  palette: palette,
                  child: Column(
                    children: [
                      CompanionAvatar(style: 'chibi', size: 90, palette: palette),
                      const SizedBox(height: 16),
                      const Text(
                        '登录',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _userCtrl,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    filled: true,
                    fillColor: palette.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const Spacer(),
                IslandPrimaryAction(
                  label: '登录',
                  loading: _loading,
                  palette: palette,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
