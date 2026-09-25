import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../storage/prefs.dart';

enum PurchaseState { idle, unavailable, pending, failed, owned }

/// StoreKit via the first-party in_app_purchase plugin — deliberately NOT
/// RevenueCat or any wrapper (App Review has flagged third-party purchase SDKs
/// in Kids Category apps). Only ever reachable from behind the parental gate.
class PurchaseService extends ChangeNotifier {
  PurchaseService(this._settings);
  final Settings _settings;

  static const productId = 'com.yunslantern.fullunlock';

  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? product;
  PurchaseState state = PurchaseState.idle;

  bool get owned => _settings.purchased;

  Future<void> init() async {
    // The web build (GitHub Pages demo) has no store; keep everything local.
    if (kIsWeb) {
      state = PurchaseState.unavailable;
      return;
    }
    try {
      _iap = InAppPurchase.instance;
      if (!await _iap!.isAvailable()) {
        state = PurchaseState.unavailable;
        return;
      }
      _sub = _iap!.purchaseStream.listen(
        _onPurchases,
        onError: (_) => _setState(PurchaseState.failed),
      );
      final resp = await _iap!.queryProductDetails({productId});
      product = resp.productDetails.isEmpty ? null : resp.productDetails.first;
      notifyListeners();
    } catch (_) {
      state = PurchaseState.unavailable;
    }
  }

  Future<void> buy() async {
    final p = product;
    if (_iap == null || p == null) return _setState(PurchaseState.unavailable);
    _setState(PurchaseState.pending);
    await _iap!.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: p),
    );
  }

  /// Required by App Review.
  Future<void> restore() async {
    if (_iap == null) return _setState(PurchaseState.unavailable);
    _setState(PurchaseState.pending);
    await _iap!.restorePurchases();
  }

  void _onPurchases(List<PurchaseDetails> list) {
    for (final d in list) {
      if (d.productID != productId) continue;
      switch (d.status) {
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _settings.purchased = true;
          _setState(PurchaseState.owned);
        case PurchaseStatus.pending:
          _setState(PurchaseState.pending);
        case PurchaseStatus.error || PurchaseStatus.canceled:
          _setState(PurchaseState.failed);
      }
      if (d.pendingCompletePurchase) _iap!.completePurchase(d);
    }
  }

  void _setState(PurchaseState s) {
    state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
