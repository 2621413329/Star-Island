import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/auth_hero_card.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/password_text_field.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/legal_agreement.dart';
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
  bool _agreedToTerms = false;
  bool _showConsentError = false;
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
    if (!_agreedToTerms) {
      setState(() {
        _showConsentError = true;
        _error = null;
      });
      return;
    }
    if (username.length < 3 || password.length < 6) {
      setState(() {
        _error = '用户名至少3位，密码至少6位';
        _showConsentError = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(authRepositoryProvider).login(
            username: username,
            password: password,
          );
      await ref.read(authProvider.notifier).setToken(token);
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
    context.go('/records');
  }

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: palette.gradientEnd,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IslandScaffold(
            palette: palette,
            child: SizedBox.expand(),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24 + keyboardInset + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
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
                        AuthHeroCard(
                          palette: palette,
                          title: '登录',
                          avatar: CompanionAvatar(
                            style: 'chibi',
                            size: 90,
                            palette: palette,
                            autoPlayOnMount: true,
                            gender:
                                ref.watch(profileProvider).valueOrNull?.gender,
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
                        PasswordTextField(
                          controller: _passCtrl,
                          fillColor: palette.card,
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
                        const SizedBox(height: 20),
                        LegalConsentRow(
                          checked: _agreedToTerms,
                          palette: palette,
                          showError: _showConsentError,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value;
                              if (value) _showConsentError = false;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        IslandPrimaryAction(
                          label: '登录',
                          loading: _loading,
                          palette: palette,
                          onPressed: _loading ? null : _submit,
                        ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => context.go('/auth/register'),
                          child: const Text('还没有账号？去注册'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
