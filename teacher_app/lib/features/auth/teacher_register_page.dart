import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/school_classes.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/island_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_classes_provider.dart';
import 'class_selector_field.dart';

class TeacherRegisterPage extends ConsumerStatefulWidget {
  const TeacherRegisterPage({super.key});

  @override
  ConsumerState<TeacherRegisterPage> createState() => _TeacherRegisterPageState();
}

class _TeacherRegisterPageState extends ConsumerState<TeacherRegisterPage> {
  final _userCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  String _className = defaultClassName;
  bool _loading = false;
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
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final nickname = _nickCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final secret = _secretCtrl.text.trim();
    if (username.length < 3 || password.length < 6) {
      setState(() => _error = '用户名至少3位，密码至少6位');
      return;
    }
    if (nickname.isEmpty) {
      setState(() => _error = '请填写昵称');
      return;
    }
    if (password != confirm) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    if (secret.isEmpty) {
      setState(() => _error = '请输入注册密钥');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(teacherRepositoryProvider).register(
            username: username,
            nickname: nickname,
            password: password,
            registrationSecret: secret,
            className: _className,
          );
      await ref.read(authProvider.notifier).setToken(token.accessToken);
      if (!mounted) return;
      context.go('/home');
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
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const Text('教师注册', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                ClassSelectorField(
                  value: _className,
                  palette: palette,
                  onChanged: (v) => setState(() => _className = v),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    filled: true,
                    fillColor: palette.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _secretCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '注册密钥',
                    hintText: '请输入学校发放的密钥',
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
                  label: '注册',
                  loading: _loading,
                  palette: palette,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
