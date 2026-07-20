import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/service/api_service.dart';

class SubscriptionController extends GetxController {
  /// StoreKit / Play Console product id (must match the store SKU exactly).
  static const String kStoreProductId = 'com.gyaaniqkids.monthly';

  static const String _appleManageUrl =
      'https://apps.apple.com/account/subscriptions';

  /// Google Play subscriptions management deep link.
  static const String _googleManageUrl =
      'https://play.google.com/store/account/subscriptions';

  final ApiService _api = ApiService.instance;
  final InAppPurchase _iap = InAppPurchase.instance;

  /// Store availability + product load state.
  final RxBool storeAvailable = false.obs;
  final RxBool loadingProduct = true.obs;

  /// True while a purchase / restore flow is in-flight (button spinner).
  final RxBool purchasing = false.obs;

  /// Non-fatal load error kept as state instead of a toast on open.
  final RxnString loadError = RxnString();

  /// The loaded store product (null until [loadProducts] succeeds).
  final Rxn<ProductDetails> product = Rxn<ProductDetails>();
  final RxList<ProductDetails> products = <ProductDetails>[].obs;

  /// Latest subscription + plan catalog fetched from the backend.
  final Rxn<SubscriptionModel> subscription = Rxn<SubscriptionModel>();
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;

  /// Distinguishes a user-tapped "Restore" (shows a snackbar) from the silent
  /// entitlement refresh we run on open.
  bool _restoreRequestedByUser = false;

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  /// Retry loading everything (e.g. from a "Try again" link).
  Future<void> reload() => _init();

  Future<void> _init() async {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('purchaseStream error: $error'),
    );

    storeAvailable.value = await _iap.isAvailable();
    if (!storeAvailable.value) {
      loadingProduct.value = false;
      loadError.value = 'In-app purchases are not available on this device.';
      return;
    }

    await loadProducts();
    await fetchMySubscription();

    // Silent restore so already-subscribed users keep their entitlement.
    await _iap.restorePurchases();
  }

  Future<void> loadProducts() async {
    loadingProduct.value = true;
    loadError.value = null;
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails({kStoreProductId});

      if (response.error != null) {
        loadError.value = response.error!.message;
        return;
      }
      if (response.productDetails.isEmpty ||
          response.notFoundIDs.contains(kStoreProductId)) {
        loadError.value = 'Subscription plan is not available right now.';
        return;
      }

      products.assignAll(response.productDetails);
      product.value = response.productDetails.first;
    } finally {
      loadingProduct.value = false;
      update();
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase flow — the server mints the token; the client never generates one.
  // ---------------------------------------------------------------------------

  /// Entry point wired to the purchase button.
  ///
  /// Mirrors the old `initializePayment()` flow — but instead of generating a
  /// token on the client, it asks the backend (Purchase Init) to mint the
  /// appAccountToken, then hands that token + productId to [buyPlan].
  Future<void> initializePayment() async {
    if (purchasing.value) return;

    // if (products.isEmpty) {
    //   _showError('Plan is still loading. Please try again in a moment.');
    //   return;
    // }

    purchasing.value = true;
    try {
      // Purchase Init — backend creates a pending Subscription row and returns
      // the appAccountToken + productId.
      final ApiResponse<Map<String, dynamic>> res =
          await _api.post<Map<String, dynamic>>(
        endpoint: ApiService.purchaseInitEndpoint,
        showLoader: false,
        data: {
          'productId': kStoreProductId,
          'deviceInfo': _deviceInfo(),
        },
      );

      final Map<String, dynamic>? data =
          res.data?['data'] as Map<String, dynamic>?;
      final String? token = data?['appAccountToken'] as String?;
      // Backend echoes the productId; fall back to our store SKU if absent.
      final String productId =
          (data?['productId'] as String?) ?? kStoreProductId;

      if (!res.success || token == null || token.isEmpty) {
        purchasing.value = false;
        _showError(
          res.message.isNotEmpty
              ? res.message
              : 'Failed to start the purchase.',
        );
        return;
      }

      // Hand the server token + productId to StoreKit.
      await buyPlan(productId, token);
      // The outcome arrives asynchronously in [_onPurchaseUpdated].
    } catch (e) {
      purchasing.value = false;
      _showError('Could not start the purchase: $e');
    }
  }

  /// Opens the native purchase sheet for [productId], tagging the transaction
  /// with the server-minted [appAccountToken].
  Future<void> buyPlan(String productId, String appAccountToken) async {
    // final ProductDetails? storeProduct =
    //     products.firstWhereOrNull((p) => p.id == productId);

    // if (storeProduct == null) {
    //   purchasing.value = false;
    //   _showError('Product not found: $productId');
    //   return;
    // }

    final product = products.firstWhereOrNull((p) => p.id == productId);

    if (product == null) {
      Get.snackbar('Error', 'Product not found');
      return;
    }

    // On iOS the plugin forwards applicationUserName as the StoreKit
    // appAccountToken the backend correlates against via the webhook.
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: appAccountToken,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Free-form diagnostics stored on the pending Subscription row (admin-only).
  Map<String, dynamic> _deviceInfo() {
    return {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'osVersion': Platform.operatingSystemVersion,
    };
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasing.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          purchasing.value = false;
          // Payment is finalized on-device. The backend flips the row to
          // `active` when Apple's server notification arrives; poll our
          // endpoint so the UI reflects the latest state.
          await fetchMySubscription();

          if (purchase.status == PurchaseStatus.purchased) {
            _showSuccess('Subscription activated.');
          } else if (_restoreRequestedByUser) {
            _showSuccess('Purchases restored.');
          }
          _restoreRequestedByUser = false;
          break;

        case PurchaseStatus.error:
          purchasing.value = false;
          _restoreRequestedByUser = false;
          _showError(purchase.error?.message ?? 'Purchase failed.');
          break;

        case PurchaseStatus.canceled:
          // User dismissed the sheet. Nothing to notify — the pending row is
          // swept to `failed` by the backend after 24h if no webhook arrives.
          purchasing.value = false;
          _restoreRequestedByUser = false;
          break;
      }

      // Always finish the transaction so it is not re-delivered on next launch.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription status
  // ---------------------------------------------------------------------------

  /// GET user/subscription → current subscription + active plan catalog.
  Future<void> fetchMySubscription() async {
    final ApiResponse<Map<String, dynamic>> res =
        await _api.get<Map<String, dynamic>>(
      endpoint: ApiService. subscriptionEndpoint,
      showLoader: false,
    );

    if (!res.success || res.data == null) {
      return; // Non-fatal: keep whatever we already have.
    }

    final Map<String, dynamic>? data =
        res.data!['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final Map<String, dynamic>? subJson =
        data['subscription'] as Map<String, dynamic>?;
    subscription.value =
        subJson == null ? null : SubscriptionModel.fromJson(subJson);

    final List<dynamic> plansJson = (data['plans'] as List?) ?? const [];
    plans.assignAll(
      plansJson
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson),
    );
    update();
  }

  /// Restore previously bought subscriptions (required by App Store review).
  Future<void> restore() async {
    _restoreRequestedByUser = true;
    purchasing.value = true;
    try {
      await _iap.restorePurchases();
      // Results arrive via [_onPurchaseUpdated]; stop spinner as a safety net.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (purchasing.value) {
          purchasing.value = false;
          _restoreRequestedByUser = false;
        }
      });
    } catch (e) {
      purchasing.value = false;
      _restoreRequestedByUser = false;
      _showError(e.toString());
    }
  }

  /// Opens the native store page where the user manages the subscription.
  Future<void> manageSubscription() async {
    final String url = Platform.isIOS ? _appleManageUrl : _googleManageUrl;
    final bool ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      _showError('Could not open subscription settings.');
    }
  }

  /// Cancels the subscription.
  ///
  /// Apple and Google don't allow apps to cancel a subscription through their
  /// own API — the user must turn off auto-renew on the native store page. So
  /// we confirm intent, explain that access stays until the current period
  /// ends, then deep-link to the store's subscription management screen.
  Future<void> cancelSubscription() async {
    final String store = Platform.isIOS ? 'the App Store' : 'Google Play';
    final bool confirmed = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Cancel Subscription?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: Text(
              "You'll be taken to $store to turn off auto-renewal. "
              'Your premium access stays active until the end of the current '
              'billing period.',
              style: const TextStyle(
                color: Color(0xFF5D6070),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text(
                  'Keep Plan',
                  style: TextStyle(
                    color: Color(0xFF5D6070),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await manageSubscription();
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }
}

/// The student's most recent subscription row (any status).
class SubscriptionModel {
  const SubscriptionModel({
    required this.productId,
    required this.planName,
    required this.status,
    required this.isEntitled,
    required this.autoRenewStatus,
    this.environment,
    this.purchaseDate,
    this.expiryDate,
    this.cancellationDate,
  });

  final String productId;
  final String planName;

  /// pending / active / in_grace_period / in_billing_retry /
  /// expired / refunded / revoked / failed
  final String status;

  /// Convenience flag from the server (true for active / in_grace_period).
  /// Do NOT use this to gate access — gating is server-side only.
  final bool isEntitled;
  final bool autoRenewStatus;
  final String? environment;

  /// All timestamps are UTC.
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final DateTime? cancellationDate;

  bool get isActive => status == 'active' || status == 'in_grace_period';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      productId: (json['productId'] ?? '') as String,
      planName: (json['planName'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      isEntitled: json['isEntitled'] == true,
      autoRenewStatus: json['autoRenewStatus'] == true,
      environment: json['environment'] as String?,
      purchaseDate: DateTime.tryParse('${json['purchaseDate'] ?? ''}'),
      expiryDate: DateTime.tryParse('${json['expiryDate'] ?? ''}'),
      cancellationDate: DateTime.tryParse('${json['cancellationDate'] ?? ''}'),
    );
  }
}

/// A plan from the backend catalog (prices are in the smallest currency unit,
/// e.g. paise for INR).
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.productId,
    required this.name,
    required this.originalPrice,
    required this.offerPrice,
    required this.currency,
    required this.durationDays,
    required this.active,
  });

  final String productId;
  final String name;
  final int originalPrice;
  final int offerPrice;
  final String currency;
  final int durationDays;
  final bool active;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      productId: (json['productId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
      offerPrice: (json['offerPrice'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? '') as String,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      active: json['active'] == true,
    );
  }
}
