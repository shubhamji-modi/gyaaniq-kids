import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';

class OnboardController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentPage = 0.obs;

  final List<OnboardPageData> pages = const [
    OnboardPageData(
      imagePath: 'assets/images/onbording_image_01.png',
      titleLineOne: 'Welcome to Your',
      titleHighlight: 'Learning Journey',
      description:
          'Master Grade 5-10 concepts with interactive quests and AI-powered help.',
      badgeText: 'Daily Streak',
      badgeValue: '07 Days',
      badgeIcon: 'trophy',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onbording_image_02.png',
      titleLineOne: 'Your Personal',
      titleHighlight: 'Learning Path',
      description:
          'Our AI adapts to your pace, ensuring you master every concept with ease.',
      badgeText: '98% Mastery',
      badgeValue: 'Science + Math',
      badgeIcon: 'trend',
    ),
    OnboardPageData(
      imagePath: 'assets/images/onbording_image_03.png',
      titleLineOne: 'Earn While You Learn',
      titleHighlight: '',
      description:
          'Collect badges, maintain streaks, and climb the leaderboard while mastering your school subjects.',
      badgeText: 'XP Rewards',
      badgeValue: 'Level Up',
      badgeIcon: 'star',
    ),
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> onNextTap() async {
    if (isLastPage) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(StorageKeys.onboardingCompleted, true);
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardPageData {
  final String imagePath;
  final String titleLineOne;
  final String titleHighlight;
  final String description;
  final String badgeText;
  final String badgeValue;
  final String badgeIcon;

  const OnboardPageData({
    required this.imagePath,
    required this.titleLineOne,
    required this.titleHighlight,
    required this.description,
    required this.badgeText,
    required this.badgeValue,
    required this.badgeIcon,
  });
}
