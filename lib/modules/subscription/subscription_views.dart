import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/appcolors.dart';
import '../menubar/purchase_subscription/views/subscription_history_views.dart';
import 'subscription_controller.dart';

class SubscriptionViews extends StatelessWidget {
  const SubscriptionViews({super.key});

  static const _features = [
    '250 Studio Credits',
    'Priority GPU Access',
    'Faster Video Processing',
    'Early Access to Features',
  ];

  @override
  Widget build(BuildContext context) {
    // Create (or reuse) the IAP controller for this screen.
    Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const _SubscriptionTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
                child: Column(
                  children: [
                    const _SubscriptionIntro(),
                    const SizedBox(height: 50),
                    _PlanCard(features: _features),
                    const SizedBox(height: 14),
                    const _SubscriptionActions(),
                    const _CancelSubscriptionButton(),
                    const SizedBox(height: 20),
                    const _SubscriptionFooter(),
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'SUBSCRIPTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 5,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.to(() => const SubscriptionHistoryViews()),
            icon: const Icon(
              Icons.history_rounded,
              color: Color(0xFF444653),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionIntro extends StatelessWidget {
  const _SubscriptionIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Unlock Premium Learning',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF181B22),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
        SizedBox(height: 15),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Get unlimited access to premium learning\n'
            'features with a single subscription plan\n'
            'designed to help you learn smarter and achieve\n'
            'your academic goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5D6070),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 42, 32, 34),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY SUBSCRIPTION',
                          style: TextStyle(
                            color: Color(0xFF1E2028),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Built for high-volume creatorsand brands.',
                          style: TextStyle(
                            color: Color(0xFF5D6070),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6864F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PlanPrice(controller: controller),
              // const SizedBox(height: 24),
              // const Text(
              //   'PER QUARTER',
              //   style: TextStyle(
              //     color: Color(0xFF666978),
              //     fontSize: 12,
              //     fontWeight: FontWeight.w600,
              //     letterSpacing: 2.4,
              //   ),
              // ),
              const SizedBox(height: 20),
              // ...features.map(
              //   (feature) => Padding(
              //     padding: const EdgeInsets.only(bottom: 24),
              //     child: _FeatureRow(
              //       label: feature,
              //       isBold: feature == features.first,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() {
                  final bool busy =
                      controller.purchasing.value ||
                      controller.loadingProduct.value;
                  final bool active = controller.isSubscribed;
                  final bool canBuy =
                      controller.storeAvailable.value &&
                      controller.product.value != null &&
                      !busy &&
                      !active;
                  return ElevatedButton(
                    onPressed: canBuy ? controller.initializePayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),
                      disabledForegroundColor: Colors.white,
                      elevation: 12,
                      shadowColor: AppColors.primary.withValues(alpha: 0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                active ? 'Subscribed' : 'Subscribe',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                active
                                    ? Icons.check_circle_outline
                                    : Icons.rocket_launch_outlined,
                                size: 22,
                              ),
                            ],
                          ),
                  );
                }),
              ),
              Obx(() {
                final String? error = controller.loadError.value;
                if (error == null || error.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Positioned(
          top: -17,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'BEST VALUE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanPrice extends StatelessWidget {
  const _PlanPrice({required this.controller});

  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingProduct.value) {
        return const SizedBox(
          height: 31,
          width: 31,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        );
      }

      final String price = controller.currentPrice;
      final String? offerPrice = controller.offerPrice;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                offerPrice ?? price,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
          ),
          if (offerPrice != null) ...[
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF8A8C96),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFF8A8C96),
                  decorationThickness: 1.6,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _SubscriptionActions extends StatelessWidget {
  const _SubscriptionActions();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: controller.restore,
          child: const Text(
            'Restore Purchases',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text('·', style: TextStyle(color: Color(0xFFC9C5DD))),
        TextButton(
          onPressed: controller.manageSubscription,
          child: const Text(
            'Manage Subscription',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelSubscriptionButton extends StatelessWidget {
  const _CancelSubscriptionButton();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      builder: (controller) => Obx(() {
        final bool active =
            controller.subscription.value?.hasEntitlement == true;
        // Cancelling only makes sense for an active subscription.
        if (!active) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton.icon(
            onPressed: controller.cancelSubscription,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'Cancel Subscription',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }),
    );
  }
}

class _SubscriptionFooter extends StatelessWidget {
  const _SubscriptionFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              color: Color(0xFF5E6271),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            children: [
              TextSpan(text: 'Questions? Visit our '),
              TextSpan(
                text: 'Help Center',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: ' or contact support.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FooterItem(label: 'No\ncommitment'),
            _FooterDot(),
            _FooterItem(label: 'Secure\nPayment'),
            _FooterDot(),
            _FooterItem(label: 'Cancel\nAnytime'),
          ],
        ),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF858899),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.55,
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFC9C5DD),
        shape: BoxShape.circle,
      ),
    );
  }
}
