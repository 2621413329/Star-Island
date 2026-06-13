import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/school_classes.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/companion_avatar.dart';
import '../../design_system/password_text_field.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/legal_agreement.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_classes_provider.dart';
import 'class_selector_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _userCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _className = defaultClassName;
  bool _loading = false;
  bool _agreedToTerms = false;
  bool _showConsentError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(schoolClassesProvider);
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nickCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final nickname = _nickCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
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
    if (nickname.isEmpty) {
      setState(() => _error = '请填写昵称');
      return;
    }
    if (password != confirm) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(appRepositoryProvider).studentRegister(
            username: username,
            nickname: nickname,
            password: password,
            className: _className,
          );
      await ref.read(authProvider.notifier).setToken(token);
      await ref.read(profileProvider.notifier).refresh();
      if (!mounted) return;
      context.go('/onboarding/gender');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: [
                IslandGlassCard(
                  palette: palette,
                  child: Column(
                    children: [
                      CompanionAvatar(
                        style: 'chibi',
                        size: 180,
                        palette: palette,
                        gender:
                            ref.watch(profileProvider).valueOrNull?.gender,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '注册',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ClassSelectorField(
                  value: _className,
                  palette: palette,
                  onChanged: (v) => setState(() => _className = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _userCtrl,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '用于登录，至少3位',
                    filled: true,
                    fillColor: palette.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nickCtrl,
                  decoration: InputDecoration(
                    labelText: '昵称',
                    hintText: '在页面中展示的名称',
                    filled: true,
                    fillColor: palette.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: _passCtrl,
                  fillColor: palette.card,
                ),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: _confirmCtrl,
                  labelText: '确认密码',
                  fillColor: palette.card,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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
                  label: '注册并上岛',
                  loading: _loading,
                  palette: palette,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => context.go('/auth'),
                  child: const Text('已有账号？去登录'),
                ),
                        const SizedBox(height: 24),
                      ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
