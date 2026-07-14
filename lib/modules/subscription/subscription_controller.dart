import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionController extends GetxController {
  /// Store product id (must match App Store Connect / Play Console exactly).
  static const String kProductId = 'com.gyaaniqkids.monthly';

  /// Apple's system page where the user can view / cancel subscriptions.
  static const String _appleManageUrl =
      'https://apps.apple.com/account/subscriptions';

  /// Google Play subscriptions management deep link.
  static const String _googleManageUrl =
      'https://play.google.com/store/account/subscriptions';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// Store availability + product load state.
  final RxBool storeAvailable = false.obs;
  final RxBool loadingProduct = true.obs;

  /// True while a purchase / restore flow is in-flight (button spinner).
  final RxBool purchasing = false.obs;

  /// Non-fatal load error kept as state instead of a toast on open.
  final RxnString loadError = RxnString();

  /// The loaded product (null until [_loadProduct] succeeds).
  final Rxn<ProductDetails> product = Rxn<ProductDetails>();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    // Listen for purchase updates before doing anything else.
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSub?.cancel(),
      onError: (Object error) {
        purchasing.value = false;
        _showError('Purchase stream error: $error');
      },
    );

    try {
      final bool available = await _iap.isAvailable();
      storeAvailable.value = available;
      if (!available) {
        loadError.value = 'In-app purchases are not available on this device.';
        loadingProduct.value = false;
        return;
      }

      await _loadProduct();
    } catch (e) {
      // Never let page-open crash / toast the user.
      loadError.value = e.toString();
      loadingProduct.value = false;
    }
  }

  /// Loads the product. Records failures in [loadError] silently — it does NOT
  /// pop an error toast, so opening the page is always clean.
  Future<void> _loadProduct() async {
    loadingProduct.value = true;
    loadError.value = null;

    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({kProductId});

      if (response.error != null) {
        loadError.value = response.error!.message;
        return;
      }

      if (response.productDetails.isEmpty) {
        loadError.value =
            'Subscription is not available yet. Please try again later.';
        debugPrint('Not found IDs: ${response.notFoundIDs}');
        return;
      }

      product.value = response.productDetails.first;
      loadError.value = null;

      debugPrint('Product Loaded');
      debugPrint('ID    : ${product.value!.id}');
      debugPrint('Title : ${product.value!.title}');
      debugPrint('Price : ${product.value!.price}');
    } catch (e) {
      loadError.value = e.toString();
    } finally {
      loadingProduct.value = false;
    }
  }

  /// Retry loading the product (e.g. from a "Try again" link).
  Future<void> reload() => _init();

  /// Called by the "Choose Pro" button.
  Future<void> buy() async {
    if (product.value == null) {
      await _loadProduct();

      if (product.value == null) {
        _showError(loadError.value ?? 'Subscription is not available.');
        return;
      }
    }

    purchasing.value = true;

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product.value!,
    );

    try {
      // Auto-renewable subscriptions are bought as non-consumables.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      purchasing.value = false;
      _showError(e.toString());
    }
  }

  /// Restore previously bought subscriptions (required by App Store review).
  Future<void> restore() async {
    purchasing.value = true;
    try {
      await _iap.restorePurchases();
      // Result arrives via [_onPurchaseUpdate]; stop spinner as a safety net.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (purchasing.value) purchasing.value = false;
      });
    } catch (e) {
      purchasing.value = false;
      _showError(e.toString());
    }
  }

  /// Opens the native store page where the user manages the subscription.
  Future<void> manageSubscription() async {
    final String url = Platform.isIOS ? _appleManageUrl : _googleManageUrl;
    final Uri uri = Uri.parse(url);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showError('Could not open subscription settings.');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasing.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          purchasing.value = false;

          debugPrint(
            'Receipt : ${purchase.verificationData.serverVerificationData}',
          );

          Get.snackbar(
            'Success',
            purchase.status == PurchaseStatus.restored
                ? 'Subscription Restored'
                : 'Subscription Activated',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          break;

        case PurchaseStatus.error:
          purchasing.value = false;
          Get.snackbar(
            'Error',
            purchase.error?.message ?? 'Purchase Failed',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          break;

        case PurchaseStatus.canceled:
          purchasing.value = false;
          break;
      }

      // Always finish the transaction so it is not re-delivered on next launch.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFC62828),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  void onClose() {
    _purchaseSub?.cancel();
    super.onClose();
  }
}
