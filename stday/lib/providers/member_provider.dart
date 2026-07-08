import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/member_models.dart';
import '../data/repositories/app_repository.dart';
import 'auth_provider.dart';

/// 会员状态缓存有效期。
const memberStatusTtl = Duration(minutes: 10);

final memberProvider =
    AsyncNotifierProvider<MemberNotifier, MemberMeModel?>(MemberNotifier.new);

final isVipProvider = Provider<bool>((ref) {
  return ref.watch(memberProvider).valueOrNull?.isVip ?? false;
});

class MemberNotifier extends AsyncNotifier<MemberMeModel?> {
  DateTime? _fetchedAt;

  @override
  Future<MemberMeModel?> build() async {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn && (previous == null || !previous.isLoggedIn)) {
        unawaited(refresh(force: true));
      } else if (!next.isLoggedIn) {
        _fetchedAt = null;
        state = const AsyncData(null);
      }
    });
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return null;
    return _fetch();
  }

  bool get isStale {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > memberStatusTtl;
  }

  Future<void> ensureFresh() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    if (!isStale && state.hasValue) return;
    await refresh();
  }

  Future<void> refresh({bool force = false}) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      _fetchedAt = null;
      state = const AsyncData(null);
      return;
    }
    if (!force && !isStale && state.hasValue) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<MemberMeModel?> _fetch() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return null;
    final model = await ref.read(memberRepositoryProvider).fetchMemberMe();
    _fetchedAt = DateTime.now();
    return model;
  }
}
