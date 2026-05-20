import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionHistoryViews extends StatelessWidget {
  const SubscriptionHistoryViews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const _SubscriptionTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'My Subscription',
                      style: TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage your learning journey and plan benefits.',
                      style: TextStyle(
                        color: Color(0xFF555A6E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 26),
                    _BillingDetailsCard(),
                    SizedBox(height: 15),
                    _HelpCenterCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTopBar extends StatelessWidget {
  const _SubscriptionTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7EAF4)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0D2F82),
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'Subscription',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0D2F82),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _BillingDetailsCard extends StatelessWidget {
  const _BillingDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE7EAF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFC7DC).withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Billing Details',
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF85879A),
                size: 25,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Course',
                    style: TextStyle(
                      color: Color(0xFF4B4F63),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Full Access (Grade 8)',
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _BillingInfoRow(
            title: 'Purchase Date',
            value: 'Dec 15, 2023',
          ),
          const SizedBox(height: 24),
          const _BillingInfoRow(
            title: 'Amount Paid',
            value: '\$199.00',
            valueColor: Color(0xFF4F54E8),
          ),
          const SizedBox(height: 24),
          const _BillingInfoRow(
            title: 'Payment Method',
            value: 'Visa **** 1234',
            leadingIcon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E8F0), thickness: 1.4),
          const SizedBox(height: 15),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Next Billing',
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD7A8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Dec 15, 2024',
                  style: TextStyle(
                    color: Color(0xFF8B5700),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Invoice Download',
                  'Invoice download started.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.white,
                  colorText: const Color(0xFF1D2231),
                  margin: const EdgeInsets.all(14),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE5E7EC),
                foregroundColor: const Color(0xFF4B4F63),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(34),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 22),
              label: const Text(
                'Download Invoice',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingInfoRow extends StatelessWidget {
  const _BillingInfoRow({
    required this.title,
    required this.value,
    this.leadingIcon,
    this.valueColor = const Color(0xFF1D2231),
  });

  final String title;
  final String value;
  final IconData? leadingIcon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4B4F63),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: const Color(0xFF4B4F63), size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HelpCenterCard extends StatelessWidget {
  const _HelpCenterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD8DAFF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help with your plan?',
            style: TextStyle(
              color: Color(0xFF4A4FD9),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Our support team is available 24/7 to assist you with any billing or plan questions.',
            style: TextStyle(
              color: Color(0xFF4B4F63),
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Visit Help Center',
                style: TextStyle(
                  color: Color(0xFF4A4FD9),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF4A4FD9),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
