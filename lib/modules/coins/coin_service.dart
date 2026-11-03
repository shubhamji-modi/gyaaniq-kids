import 'package:get/get.dart';

import '../../core/service/api_service.dart';
import 'views/coin_wallet_views.dart';

/// The student's Library coin balance (`GET /user/coins`).
///
/// Read-only: coins are only ever awarded by the server when an admin
/// approves the student's own Library request. Fetched when a screen that
/// shows it opens and after a coin notification — never polled.
class CoinService {
  CoinService._();

  static final CoinService instance = CoinService._();

  /// `null` until the first successful fetch.
  final RxnInt balance = RxnInt();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Future<void>? _inFlight;

  /// Re-reads the balance; concurrent callers share one request.
  Future<void> refresh() => _inFlight ??= _fetch().whenComplete(() {
    _inFlight = null;
  });

  Future<void> _fetch() async {
    isLoading.value = true;
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_COINS,
      showLoader: false,
      fromJson: (json) => json,
    );
    isLoading.value = false;

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final data = body['data'];
    final value = data is Map ? data['balance'] : null;
    if (response.success && value is num) {
      balance.value = value.toInt();
      error.value = '';
      return;
    }
    error.value = response.statusCode == 403
        ? 'Coins are only for student accounts.'
        : (body['message']?.toString() ?? '').trim().isNotEmpty
        ? body['message'].toString()
        : "We couldn't load your coins. Please try again.";
  }

  /// Opens the wallet, which fetches a fresh balance.
  static Future<void> openWallet() async {
    await Get.to(() => const CoinWalletViews(), preventDuplicates: true);
  }

  /// Dropped on logout so the next student never sees this one's balance.
  void reset() {
    balance.value = null;
    error.value = '';
    isLoading.value = false;
  }
}
