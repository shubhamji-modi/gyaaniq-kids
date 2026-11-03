import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../library/views/library_widgets.dart';
import '../coin_service.dart';

const Color _coinGold = Color(0xFFE8A317);
const Color _coinGoldSoft = Color(0xFFFFF4D9);

/// The student's coin wallet: current balance and how coins are earned.
/// Opened from a balance pill or a `studentCoins` notification.
class CoinWalletViews extends StatefulWidget {
  const CoinWalletViews({super.key});

  @override
  State<CoinWalletViews> createState() => _CoinWalletViewsState();
}

class _CoinWalletViewsState extends State<CoinWalletViews> {
  final CoinService _coins = CoinService.instance;

  @override
  void initState() {
    super.initState();
    // Always the authenticated student's real balance, never a value carried
    // in a notification.
    unawaited(_coins.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryTopBar(title: 'My coins'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _coins.refresh,
                child: Obx(() {
                  final balance = _coins.balance.value;
                  if (balance == null && _coins.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (balance == null) {
                    return LibraryMessageView(
                      icon: Icons.cloud_off_rounded,
                      title: "We couldn't load your coins",
                      message: _coins.error.value,
                      actionLabel: 'Try again',
                      onAction: _coins.refresh,
                    );
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                    children: [
                      _BalanceCard(balance: balance),
                      const SizedBox(height: 20),
                      const _HowToEarn(),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5B83D), Color(0xFFD98C0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _coinGold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total coins',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToEarn extends StatelessWidget {
  const _HowToEarn();

  @override
  Widget build(BuildContext context) {
    const lines = [
      (
        icon: Icons.menu_book_rounded,
        text: 'Ask for a new book in the Library. When it is approved, you get coins.',
      ),
      (
        icon: Icons.note_add_outlined,
        text: 'Ask for a new chapter. When it is approved, you get coins.',
      ),
      (
        icon: Icons.redeem_rounded,
        text: 'Coins are saved for rewards and discounts — coming soon!',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LibraryPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to earn coins',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final line in lines) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _coinGoldSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(line.icon, color: _coinGold, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line.text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Small tappable "🪙 125" chip for a top bar or the home screen. Fetches the
/// balance when it appears and opens the wallet on tap.
class CoinBalancePill extends StatefulWidget {
  const CoinBalancePill({super.key});

  @override
  State<CoinBalancePill> createState() => _CoinBalancePillState();
}

class _CoinBalancePillState extends State<CoinBalancePill> {
  final CoinService _coins = CoinService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_coins.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _coinGoldSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: CoinService.openWallet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: _coinGold,
                size: 18,
              ),
              const SizedBox(width: 4),
              Obx(
                () => Text(
                  '${_coins.balance.value ?? '–'}',
                  style: const TextStyle(
                    color: Color(0xFF8A5A00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
