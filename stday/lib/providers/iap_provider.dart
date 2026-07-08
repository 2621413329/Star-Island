import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/api/api_client.dart';
import '../core/membership/iap_product_ids.dart';
import '../data/repositories/app_repository.dart';
import 'member_provider.dart';

class IapCatalogState {
  const IapCatalogState({
    this.available = false,
    this.loading = false,
    this.purchasing = false,
    this.restoring = false,
    this.products = const [],
    this.error,
  });

  final bool available;
  final bool loading;
  final bool purchasing;
  final bool restoring;
  final List<ProductDetails> products;
  final String? error;

  IapCatalogState copyWith({
    bool? available,
    bool? loading,
    bool? purchasing,
    bool? restoring,
    List<ProductDetails>? products,
    String? error,
    bool clearError = false,
  }) {
    return IapCatalogState(
      available: available ?? this.available,
      loading: loading ?? this.loading,
      purchasing: purchasing ?? this.purchasing,
      restoring: restoring ?? this.restoring,
      products: products ?? this.products,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final iapCatalogProvider =
    NotifierProvider<IapCatalogNotifier, IapCatalogState>(IapCatalogNotifier.new);

class IapCatalogNotifier extends Notifier<IapCatalogState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final List<String> _restoreBuffer = [];
  Completer<void>? _restoreCompleter;

  @override
  IapCatalogState build() {
    ref.onDispose(() {
      _purchaseSub?.cancel();
      _purchaseSub = null;
    });
    return const IapCatalogState();
  }

  bool get _supportsStore => !kIsWeb && Platform.isIOS;

  Future<void> ensureInitialized() async {
    if (!_supportsStore) {
      state = state.copyWith(available: false);
      return;
    }
    if (_purchaseSub != null) return;

    final storeAvailable = await _iap.isAvailable();
    state = state.copyWith(available: storeAvailable);
    if (!storeAvailable) return;

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        state = state.copyWith(
          purchasing: false,
          restoring: false,
          error: error.toString(),
        );
        _restoreCompleter?.complete();
        _restoreCompleter = null;
      },
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_supportsStore) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await _iap.queryProductDetails(IapProductIds.all);
      if (response.error != null) {
        state = state.copyWith(
          loading: false,
          error: response.error!.message,
        );
        return;
      }
      final products = response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      state = state.copyWith(loading: false, products: products);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (!_supportsStore) {
      state = state.copyWith(error: '当前平台不支持 App Store 内购');
      return;
    }
    state = state.copyWith(purchasing: true, clearError: true);
    try {
      final param = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        state = state.copyWith(
          purchasing: false,
          error: '无法发起购买，请稍后重试',
        );
      }
    } catch (e) {
      state = state.copyWith(purchasing: false, error: e.toString());
    }
  }

  Future<bool> restore() async {
    if (!_supportsStore) {
      state = state.copyWith(error: '当前平台不支持 App Store 内购');
      return false;
    }
    state = state.copyWith(restoring: true, clearError: true);
    _restoreBuffer.clear();
    _restoreCompleter = Completer<void>();
    try {
      await _iap.restorePurchases();
      await _restoreCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );
      if (_restoreBuffer.isEmpty) {
        state = state.copyWith(restoring: false, error: '未找到可恢复的购买记录');
        return false;
      }
      await ref
          .read(iapRepositoryProvider)
          .restorePurchases(List<String>.from(_restoreBuffer));
      await ref.read(memberProvider.notifier).refresh(force: true);
      state = state.copyWith(restoring: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(restoring: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(restoring: false, error: e.toString());
      return false;
    } finally {
      _restoreCompleter = null;
      _restoreBuffer.clear();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          purchasing: false,
          restoring: false,
          error: purchase.error?.message ?? '购买失败',
        );
        _finishRestoreWait();
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(purchasing: false, restoring: false);
        _finishRestoreWait();
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final jws = purchase.verificationData.serverVerificationData.trim();
        if (jws.isNotEmpty) {
          try {
            if (purchase.status == PurchaseStatus.restored) {
              _restoreBuffer.add(jws);
            } else {
              await ref.read(iapRepositoryProvider).verifyPurchase(jws);
              await ref.read(memberProvider.notifier).refresh(force: true);
              state = state.copyWith(purchasing: false, clearError: true);
            }
          } on ApiException catch (e) {
            state = state.copyWith(
              purchasing: false,
              restoring: false,
              error: e.message,
            );
          } catch (e) {
            state = state.copyWith(
              purchasing: false,
              restoring: false,
              error: e.toString(),
            );
          }
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    _finishRestoreWait();
  }

  void _finishRestoreWait() {
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
