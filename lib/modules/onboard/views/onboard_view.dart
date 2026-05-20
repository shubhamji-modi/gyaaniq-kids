import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboard_controller.dart';

class OnboardView extends StatelessWidget {
  const OnboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.pages.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  final item = controller.pages[index];
                  return _OnboardSlide(item: item);
                },
              ),
            ),
            Obx(
              () => Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  children: [
                    _PageDots(
                      total: controller.pages.length,
                      currentIndex: controller.currentPage.value,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: controller.onNextTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF474CD4),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(
                            0xFF474CD4,
                          ).withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              controller.isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7DFEF)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFF947600),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Join 50k+ students learning today',
                            style: TextStyle(
                              color: Color(0xFF475065),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.item});

  final OnboardPageData item;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF152964).withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: AspectRatio(
                aspectRatio: 0.94,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.imagePath, fit: BoxFit.cover),
                    // DecoratedBox(
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       begin: Alignment.topCenter,
                    //       end: Alignment.bottomCenter,
                    //       colors: [
                    //         Color(0xFF123486).withValues(alpha: 0.02),
                    //         Color(0xFF123486).withValues(alpha: 0.10),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.titleLineOne,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF123486),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
          if (item.titleHighlight.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.titleHighlight,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: item.titleLineOne == 'Welcome to Your'
                    ? const Color(0xFF2CC768)
                    : const Color(0xFF123486),
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -1,
              ),
            ),
          ],
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4A4F63),
                fontSize: 16,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.total, required this.currentIndex});

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 12,
          height: 9,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF474CD4) : const Color(0xFFC8CBDB),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
