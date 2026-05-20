import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/quiz_daily_result_controller.dart';

class QuizDailyResult extends StatelessWidget {
  const QuizDailyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizDailyResultController>(tag: 'daily_quiz_result');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const _ResultTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                child: Column(
                  children: [
                    const Text(
                      'Quiz Completed!',
                      style: TextStyle(
                        color: Color(0xFF4950DB),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fantastic effort! You have completed the daily challenge.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF505165),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          const Text(
                            'FINAL SCORE',
                            style: TextStyle(
                              color: Color(0xFF484B60),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${controller.score}',
                                  style: const TextStyle(
                                    color: Color(0xFF4D4FE1),
                                    fontSize: 50,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TextSpan(
                                  text: '/${controller.totalQuestions}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B6E82),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: controller.accuracy,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E5EC),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4D4FE1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.gps_fixed_rounded,
                            iconBackground: const Color(0xFFF1D9FF),
                            iconColor: const Color(0xFF8B36D9),
                            title: controller.accuracyText,
                            subtitle: 'Accuracy',
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.timer_outlined,
                            iconBackground: const Color(0xFFFFDBAB),
                            iconColor: const Color(0xFF9C6200),
                            title: controller.formattedElapsedTime,
                            subtitle: 'Time Taken',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecoration(borderColor: const Color(0xFFD9D8FF)),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D63F0),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5D63F0).withValues(alpha: 0.26),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Level Up!',
                                  style: TextStyle(
                                    color: Color(0xFF202436),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '+${controller.xpEarned} XP Gained',
                                  style: const TextStyle(
                                    color: Color(0xFF505165),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'XP',
                            style: TextStyle(
                              color: Color(0xFF4D4FE1),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.reviewAnswers,
                        icon: const Icon(Icons.assignment_turned_in_outlined, size: 22),
                        label: const Text('Review Answers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D4FE1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.tryAgain,
                            icon: const Icon(Icons.refresh_rounded, size: 22),
                            label: const Text('Try Again'),
                            style: _secondaryButtonStyle(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.goHome,
                            icon: const Icon(Icons.home_outlined, size: 28),
                            label: const Text('Home'),
                            style: _secondaryButtonStyle(),
                          ),
                        ),
                      ],
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

class _ResultTopBar extends StatelessWidget {
  const _ResultTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF113A90),
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Quiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF123887),
                fontSize: 18,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF202436),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF505165),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color borderColor = const Color(0x00000000)}) {
  final hasBorder = borderColor != const Color(0x00000000);
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    border: hasBorder ? Border.all(color: borderColor, width: 1.6) : null,
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFDCE2F3).withValues(alpha: 0.55),
        blurRadius: 26,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

ButtonStyle _secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF202436),
    side: const BorderSide(color: Color(0xFFD1CEEF), width: 1.6),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );
}
