import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/service/api_service.dart';
import '../../core/service/session_manager.dart';

enum PurchaseFlowStatus {
  idle,
  loading,
  pending,
  purchased,
  restored,
  canceled,
  error,
}

class SubscriptionController extends GetxController {
  /// StoreKit / Play Console product id (must match the store SKU exactly).
  static const String kAppleStoreProductId = 'com.gyaaniqkids.monthly';
  static const String kGoogleStoreProductId = 'com.gyaaniqkids.monthly';
  static const String kAndroidBasePlanId = 'monthly';
  static const String kGooglePackageName = 'com.gyaaniqkids.app';

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
  final Rx<PurchaseFlowStatus> purchaseStatus = PurchaseFlowStatus.idle.obs;

  /// Non-fatal load error kept as state instead of a toast on open.
  final RxnString loadError = RxnString();
  final RxnString purchaseError = RxnString();

  /// The loaded store product (null until [loadProducts] succeeds).
  final Rxn<ProductDetails> product = Rxn<ProductDetails>();
  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final Rxn<ProductDetails> offerProduct = Rxn<ProductDetails>();

  /// Latest subscription + plan catalog fetched from the backend.
  final Rxn<SubscriptionModel> subscription = Rxn<SubscriptionModel>();
  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;

  /// Distinguishes a user-tapped "Restore" (shows a snackbar) from the silent
  /// entitlement refresh we run on open.
  bool _restoreRequestedByUser = false;
  final Set<String> _successNotifiedPurchaseKeys = <String>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdatesSubscription;

  bool get isSubscribed => subscription.value?.hasEntitlement == true;

  String get currentStoreProductId =>
      Platform.isAndroid ? kGoogleStoreProductId : kAppleStoreProductId;

  String get currentPrice => product.value?.price ?? '--';

  String? get offerPrice {
    final ProductDetails? offer = offerProduct.value;
    if (offer == null || offer.id != product.value?.id) return null;
    if (offer.price == product.value?.price) return null;
    return offer.price;
  }

  String get subscriptionState {
    final SubscriptionModel? sub = subscription.value;
    if (sub?.hasEntitlement == true) return 'active';
    if (sub != null && sub.status.isNotEmpty) return sub.status;
    return 'inactive';
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _purchaseUpdatesSubscription?.cancel();
    super.onClose();
  }

  /// Retry loading everything (e.g. from a "Try again" link).
  Future<void> reload() => _init();

  Future<void> _init() async {
    purchaseStatus.value = PurchaseFlowStatus.loading;
    _purchaseUpdatesSubscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _purchaseUpdatesSubscription?.cancel(),
      onError: (error) {
        if (_isUserCancelledPurchaseError(error)) {
          purchaseStatus.value = PurchaseFlowStatus.canceled;
          return;
        }
        purchaseStatus.value = PurchaseFlowStatus.error;
        purchaseError.value = _friendlyPurchaseError(error);
        debugPrint('purchaseStream error: ${purchaseError.value}');
      },
    );

    storeAvailable.value = await _iap.isAvailable();
    if (!storeAvailable.value) {
      loadingProduct.value = false;
      loadError.value = 'In-app purchases are not available on this device.';
      purchaseStatus.value = PurchaseFlowStatus.error;
      return;
    }

    await loadProducts();
    await fetchMySubscription();
    purchaseStatus.value = PurchaseFlowStatus.idle;

    // Silent restore so already-subscribed users keep their entitlement.
    await _iap.restorePurchases();
  }

  Future<void> loadProducts() async {
    loadingProduct.value = true;
    loadError.value = null;
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails({
        currentStoreProductId,
      });

      if (response.error != null) {
        loadError.value = response.error!.message;
        return;
      }
      if (response.productDetails.isEmpty ||
          response.notFoundIDs.contains(currentStoreProductId)) {
        loadError.value = 'Subscription plan is not available right now.';
        return;
      }

      products.assignAll(response.productDetails);
      product.value = _selectMonthlyProduct(response.productDetails);
      offerProduct.value = _selectMonthlyOffer(response.productDetails);
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

    if (!storeAvailable.value) {
      _showError('Google Play Billing is not available on this device.');
      return;
    }
    if (product.value == null) {
      _showError('Plan is still loading. Please try again in a moment.');
      return;
    }
    if (Platform.isAndroid && !await _isInstalledFromPlayStore()) {
      _showError(
        'Google Play Billing works only when this app is installed from '
        'Google Play internal testing/production. Please install the latest '
        'test build from the Play Store link.',
      );
      return;
    }

    purchasing.value = true;
    purchaseStatus.value = PurchaseFlowStatus.loading;
    purchaseError.value = null;
    try {
      final bool isAndroid = Platform.isAndroid;

      // Android uses Google init and returns obfuscatedAccountId.
      // iOS keeps the existing Apple init and returns appAccountToken.
      final ApiResponse<Map<String, dynamic>> res = await _api
          .post<Map<String, dynamic>>(
            endpoint: isAndroid
                ? ApiService.googlePurchaseInitEndpoint
                : ApiService.purchaseInitEndpoint,
            showLoader: false,
            data: {
              'productId': currentStoreProductId,
              'deviceInfo': _deviceInfo(),
            },
          );

      final Map<String, dynamic>? data =
          res.data?['data'] as Map<String, dynamic>?;
      final String? token = isAndroid
          ? (data?['obfuscatedAccountId'] as String?)
          : (data?['appAccountToken'] as String?);
      // Backend echoes the productId; fall back to our store SKU if absent.
      final String productId =
          (data?['productId'] as String?) ?? currentStoreProductId;

      if (res.success && isAndroid && data?['reused'] == true) {
        await SessionManager.instance.setHasActiveSubscription(true);
        await fetchMySubscription();
        purchasing.value = false;
        purchaseStatus.value = PurchaseFlowStatus.restored;
        _showSuccess('Subscription already active.');
        return;
      }

      if (!res.success || token == null || token.isEmpty) {
        purchasing.value = false;
        purchaseStatus.value = PurchaseFlowStatus.error;
        purchaseError.value = res.message.isNotEmpty
            ? res.message
            : 'Failed to start the purchase.';
        _showError(
          res.message.isNotEmpty
              ? res.message
              : 'Failed to start the purchase.',
        );
        return;
      }

      // Hand the server token + productId to StoreKit / Google Play.
      await buyPlan(productId, token);
      // The outcome arrives asynchronously in [_onPurchaseUpdated].
    } catch (e) {
      purchasing.value = false;
      if (_isUserCancelledPurchaseError(e)) {
        purchaseStatus.value = PurchaseFlowStatus.canceled;
        return;
      }
      purchaseStatus.value = PurchaseFlowStatus.error;
      purchaseError.value = _friendlyPurchaseError(e);
      debugPrint('Could not start the purchase: ${purchaseError.value}');
      _showError('Could not start the purchase. ${purchaseError.value}');
    }
  }

  /// Opens the native purchase sheet for [productId], tagging the transaction
  /// with the server-minted [appAccountToken].
  Future<void> buyPlan(String productId, String appAccountToken) async {
    final ProductDetails? selectedProduct = offerProduct.value?.id == productId
        ? offerProduct.value
        : product.value?.id == productId
        ? product.value
        : products.firstWhereOrNull((p) => p.id == productId);

    if (selectedProduct == null) {
      purchasing.value = false;
      purchaseStatus.value = PurchaseFlowStatus.error;
      _showError('Product not found: $productId');
      return;
    }

    final PurchaseParam purchaseParam;
    if (Platform.isAndroid && selectedProduct is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: selectedProduct,
        applicationUserName: appAccountToken,
        offerToken: selectedProduct.offerToken,
      );
    } else {
      // On iOS the plugin forwards applicationUserName as the StoreKit
      // appAccountToken the backend correlates against via the webhook.
      purchaseParam = PurchaseParam(
        productDetails: selectedProduct,
        applicationUserName: appAccountToken,
      );
    }
    final bool launched = await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!launched) {
      purchasing.value = false;
      purchaseStatus.value = PurchaseFlowStatus.error;
      purchaseError.value = 'Could not open Google Play Billing.';
      _showError('Could not open Google Play Billing.');
    }
  }

  /// Free-form diagnostics stored on the pending Subscription row (admin-only).
  Map<String, dynamic> _deviceInfo() {
    return {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'osVersion': Platform.operatingSystemVersion,
    };
  }

  Future<bool> _isInstalledFromPlayStore() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return info.installerStore == 'com.android.vending';
    } catch (e) {
      debugPrint('Could not read installer store: $e');
      return false;
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasing.value = true;
          purchaseStatus.value = PurchaseFlowStatus.pending;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool verified = await _verifyPurchaseOnServer(purchase);
          if (verified) {
            await SessionManager.instance.setHasActiveSubscription(true);
            await fetchMySubscription();
            purchaseStatus.value = purchase.status == PurchaseStatus.purchased
                ? PurchaseFlowStatus.purchased
                : PurchaseFlowStatus.restored;

            if (purchase.status == PurchaseStatus.purchased) {
              _showPurchaseSuccessOnce(purchase, 'Subscription activated.');
            } else if (_restoreRequestedByUser) {
              _showPurchaseSuccessOnce(purchase, 'Purchases restored.');
            }
          } else {
            await SessionManager.instance.setHasActiveSubscription(false);
            purchaseStatus.value = PurchaseFlowStatus.error;
            if (_restoreRequestedByUser) {
              _showError('No active subscription found to restore.');
            } else if (purchase.status == PurchaseStatus.purchased) {
              _showError(
                'Purchase received, but subscription is still waiting for '
                'server confirmation. Please try Restore Purchases in a moment.',
              );
            }
          }
          purchasing.value = false;
          _restoreRequestedByUser = false;
          break;

        case PurchaseStatus.error:
          purchasing.value = false;
          _restoreRequestedByUser = false;
          if (_isUserCancelledPurchaseError(purchase.error?.code) ||
              _isUserCancelledPurchaseError(purchase.error?.message)) {
            purchaseStatus.value = PurchaseFlowStatus.canceled;
            break;
          }
          purchaseStatus.value = PurchaseFlowStatus.error;
          purchaseError.value = _friendlyPurchaseError(
            purchase.error?.message ?? 'Purchase failed.',
          );
          _showError(purchaseError.value ?? 'Purchase failed.');
          break;

        case PurchaseStatus.canceled:
          // User dismissed the sheet. Nothing to notify — the pending row is
          // swept to `failed` by the backend after 24h if no webhook arrives.
          purchasing.value = false;
          _restoreRequestedByUser = false;
          purchaseStatus.value = PurchaseFlowStatus.canceled;
          break;
      }

      // Android is acknowledged by the backend inside /google/verify.
      // StoreKit still needs client-side completion.
      if (!Platform.isAndroid && purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription status
  // ---------------------------------------------------------------------------

  /// GET user/subscription → current subscription + active plan catalog.
  Future<void> fetchMySubscription() async {
    final ApiResponse<Map<String, dynamic>> res = await _api
        .get<Map<String, dynamic>>(
          endpoint: ApiService.subscriptionEndpoint,
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
    subscription.value = subJson == null
        ? null
        : SubscriptionModel.fromJson(subJson);
    await SessionManager.instance.setHasActiveSubscription(
      subscription.value?.hasEntitlement == true,
    );

    final List<dynamic> plansJson = (data['plans'] as List?) ?? const [];
    plans.assignAll(
      plansJson.whereType<Map<String, dynamic>>().map(
        SubscriptionPlan.fromJson,
      ),
    );
    update();
  }

  /// Restore previously bought subscriptions (required by App Store review).
  Future<void> restore() async {
    _restoreRequestedByUser = true;
    purchasing.value = true;
    purchaseStatus.value = PurchaseFlowStatus.loading;
    try {
      await _iap.restorePurchases();
      // Results arrive via [_onPurchaseUpdated]; stop spinner as a safety net.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (purchasing.value) {
          purchasing.value = false;
          _restoreRequestedByUser = false;
          purchaseStatus.value = PurchaseFlowStatus.idle;
        }
      });
    } catch (e) {
      purchasing.value = false;
      _restoreRequestedByUser = false;
      if (_isUserCancelledPurchaseError(e)) {
        purchaseStatus.value = PurchaseFlowStatus.canceled;
        return;
      }
      purchaseStatus.value = PurchaseFlowStatus.error;
      purchaseError.value = _friendlyPurchaseError(e);
      _showError(purchaseError.value ?? 'Restore failed.');
    }
  }

  ProductDetails _selectMonthlyProduct(List<ProductDetails> availableProducts) {
    final List<GooglePlayProductDetails> monthlyAndroidProducts =
        availableProducts
            .whereType<GooglePlayProductDetails>()
            .where(_isAndroidMonthlyBasePlan)
            .toList();

    final GooglePlayProductDetails? regularMonthly = monthlyAndroidProducts
        .firstWhereOrNull((p) => _androidOfferDetails(p)?.offerId == null);
    return regularMonthly ??
        monthlyAndroidProducts.firstOrNull ??
        availableProducts.first;
  }

  ProductDetails? _selectMonthlyOffer(List<ProductDetails> availableProducts) {
    final List<GooglePlayProductDetails> monthlyAndroidProducts =
        availableProducts
            .whereType<GooglePlayProductDetails>()
            .where(_isAndroidMonthlyBasePlan)
            .toList();

    return monthlyAndroidProducts.firstWhereOrNull(
          (p) => _androidOfferDetails(p)?.offerId != null,
        ) ??
        monthlyAndroidProducts.firstOrNull;
  }

  bool _isAndroidMonthlyBasePlan(GooglePlayProductDetails productDetails) {
    return _androidOfferDetails(productDetails)?.basePlanId ==
        kAndroidBasePlanId;
  }

  SubscriptionOfferDetailsWrapper? _androidOfferDetails(
    GooglePlayProductDetails productDetails,
  ) { 
    final int? index = productDetails.subscriptionIndex;
    final offers = productDetails.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) {
      return null;
    }
    return offers[index];
  }

  Future<bool> _verifyPurchaseOnServer(PurchaseDetails purchase) async {
    try {
      if (purchase.productID != currentStoreProductId) {
        debugPrint(
          'Ignoring purchase for unknown product: ${purchase.productID}',
        );
        return false;
      }

      final String token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty) {
        debugPrint('Purchase verification token is empty.');
        return false;
      }

      if (Platform.isAndroid) {
        return _verifyGooglePurchaseOnServer(
          productId: purchase.productID,
          purchaseToken: token,
        );
      }

      // Apple is finalized by the backend/webhook flow. Do not mark the app as
      // subscribed from local StoreKit state alone, because restored/expired
      // transactions can otherwise leave the UI saying "Subscribed" while the
      // App Store only shows an inactive subscription.
      return _waitForAppleBackendEntitlement();
    } catch (e) {
      debugPrint('Purchase verification failed: $e');
      return false;
    }
  }

  Future<bool> _waitForAppleBackendEntitlement() async {
    for (int attempt = 0; attempt < 5; attempt++) {
      await fetchMySubscription();
      if (subscription.value?.hasEntitlement == true) {
        return true;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  Future<bool> _verifyGooglePurchaseOnServer({
    required String productId,
    required String purchaseToken,
  }) async {
    final ApiResponse<Map<String, dynamic>> res = await _api
        .post<Map<String, dynamic>>(
          endpoint: ApiService.googleVerifyEndpoint,
          showLoader: false,
          data: {'productId': productId, 'purchaseToken': purchaseToken},
        );

    if (!res.success || res.data == null) {
      purchaseError.value = res.message.isNotEmpty
          ? res.message
          : 'Google purchase verification failed.';
      debugPrint('Google purchase verification failed: ${res.message}');
      return false;
    }

    final Map<String, dynamic>? data =
        res.data!['data'] as Map<String, dynamic>?;
    if (data == null) return false;

    subscription.value = SubscriptionModel.fromJson(data);
    final bool entitled =
        data['isEntitled'] == true ||
        data['status'] == 'active' ||
        data['status'] == 'in_grace_period';
    await SessionManager.instance.setHasActiveSubscription(entitled);
    return entitled;
  }

  /// Opens the native store page where the user manages the subscription.
  Future<void> manageSubscription() async {
    final String url = Platform.isIOS
        ? _appleManageUrl
        : '$_googleManageUrl?sku=${Uri.encodeComponent(kGoogleStoreProductId)}'
              '&package=${Uri.encodeComponent(kGooglePackageName)}';
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
    final bool confirmed =
        await Get.dialog<bool>(
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

  void _showPurchaseSuccessOnce(PurchaseDetails purchase, String message) {
    final String key = _purchaseNotificationKey(purchase);
    if (!_successNotifiedPurchaseKeys.add(key)) return;
    _showSuccess(message);
  }

  String _purchaseNotificationKey(PurchaseDetails purchase) {
    final String? purchaseId = purchase.purchaseID;
    if (purchaseId != null && purchaseId.isNotEmpty) {
      return purchaseId;
    }
    final String token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty) {
      return token;
    }
    return '${purchase.productID}:${purchase.transactionDate}:${purchase.status}';
  }

  bool _isUserCancelledPurchaseError(Object? error) {
    if (error == null) return false;
    if (error is PlatformException) {
      final String code = error.code.toLowerCase();
      if (code.contains('cancel')) return true;
    }
    final String text = error.toString().toLowerCase();
    return text.contains('usercancelled') ||
        text.contains('user cancelled') ||
        text.contains('purchasecancelled') ||
        text.contains('payment cancelled');
  }

  String _friendlyPurchaseError(Object error) {
    if (_isUserCancelledPurchaseError(error)) {
      return 'Purchase cancelled.';
    }
    if (error is PlatformException) {
      final String? message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
      return 'Purchase failed. Please try again.';
    }
    final String message = error.toString().trim();
    if (message.isEmpty) {
      return 'Purchase failed. Please try again.';
    }
    final int stacktraceIndex = message.indexOf('Stacktrace:');
    if (stacktraceIndex > 0) {
      return message.substring(0, stacktraceIndex).trim();
    }
    return message;
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
  bool get hasEntitlement => isEntitled || isActive;

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
