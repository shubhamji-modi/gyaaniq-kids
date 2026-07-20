import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../subscription/subscription_controller.dart';

class SubscriptionHistoryViews extends StatelessWidget {
  const SubscriptionHistoryViews({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the controller created by the Subscription screen; create one as a
    // fallback so this screen can also be opened standalone.
    final SubscriptionController controller =
        Get.isRegistered<SubscriptionController>()
            ? Get.find<SubscriptionController>()
            : Get.put(SubscriptionController());
    // Refresh so the latest backend state is reflected when opening history.
    controller.fetchMySubscription();

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
                  children: [
                    const Text(
                      'My Subscription',
                      style: TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Manage your learning journey and plan benefits.',
                      style: TextStyle(
                        color: Color(0xFF555A6E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Only render the billing card when the user actually has an
                    // active subscription; otherwise skip it (no empty "—" card).
                    Obx(() {
                      final bool active =
                          controller.subscription.value?.isActive ?? false;
                      if (!active) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 15),
                        child: _BillingDetailsCard(),
                      );
                    }),
                    const _HelpCenterCard(),
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

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final DateTime d = date.toLocal();
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency.isEmpty ? '' : '$currency ';
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return '—';
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (controller) => Obx(() {
        final SubscriptionModel? sub = controller.subscription.value;
        final SubscriptionPlan? plan = controller.plans.firstWhereOrNull(
          (p) => p.productId == sub?.productId,
        );

        final String courseName =
            (sub?.planName.isNotEmpty ?? false) ? sub!.planName : '—';

        final String amountPaid = plan == null
            ? '—'
            : '${_currencySymbol(plan.currency)}${plan.offerPrice}';

        final bool active = sub?.isActive ?? false;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Plan',
                        style: TextStyle(
                          color: Color(0xFF4B4F63),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      courseName,
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _BillingInfoRow(
                title: 'Purchase Date',
                value: _formatDate(sub?.purchaseDate),
              ),
              const SizedBox(height: 24),
              _BillingInfoRow(
                title: 'Amount Paid',
                value: amountPaid,
                valueColor: const Color(0xFF4F54E8),
              ),
              const SizedBox(height: 24),
              _BillingInfoRow(
                title: 'Status',
                value: _statusLabel(sub?.status ?? ''),
                valueColor:
                    active ? const Color(0xFF1F9D55) : const Color(0xFF1D2231),
              ),
              const SizedBox(height: 24),
              _BillingInfoRow(
                title: 'Auto Renew',
                value: (sub?.autoRenewStatus ?? false) ? 'On' : 'Off',
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
                    child: Text(
                      _formatDate(sub?.expiryDate),
                      style: const TextStyle(
                        color: Color(0xFF8B5700),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _BillingInfoRow extends StatelessWidget {
  const _BillingInfoRow({
    required this.title,
    required this.value,
    this.valueColor = const Color(0xFF1D2231),
  });

  final String title;
  final String value;
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
