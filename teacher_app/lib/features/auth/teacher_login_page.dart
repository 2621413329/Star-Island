import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/repositories/teacher_repository.dart';
import '../../design_system/island_ui.dart';
import '../../providers/auth_provider.dart';

class TeacherLoginPage extends ConsumerStatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  ConsumerState<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends ConsumerState<TeacherLoginPage> {
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
      final token = await ref.read(teacherRepositoryProvider).login(
            username: username,
            password: password,
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
                const SizedBox(height: 24),
                IslandGlassCard(
                  palette: palette,
                  child: const Column(
                    children: [
                      Icon(Icons.school_rounded, size: 64, color: Color(0xFFE8A87C)),
                      SizedBox(height: 12),
                      Text(
                        '教师工作台',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      SizedBox(height: 4),
                      Text('成长伙伴 · 班级心情关怀', style: TextStyle(color: Color(0xFF8C7B6B))),
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
                  onSubmitted: (_) {
                    if (!_loading) _submit();
                  },
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => context.go('/register'),
                  child: const Text('还没有账号？去注册'),
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
