import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/quiz_daily_result_controller.dart';

class QuizDailyResult extends StatelessWidget {
  const QuizDailyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizDailyResultController>(
      tag: 'daily_quiz_result',
    );

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          controller.backToSubjects();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F1FB),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                controller.passed
                    ? 'assets/images/result_win.jpg'
                    : 'assets/images/result_lose.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                _ResultHeader(controller: controller),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      children: [
                        _FinalScoreCard(controller: controller),
                        const SizedBox(height: 10),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _PercentageCard(controller: controller),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ImprovementCard(controller: controller),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AnswersBreakdownCard(controller: controller),
                        const SizedBox(height: 10),
                        _AttemptMetaCard(controller: controller),
                        const SizedBox(height: 10),
                        _LevelUpCard(controller: controller),
                        const SizedBox(height: 12),
                        _PrimaryButton(
                          label: 'Review Answers',
                          icon: Icons.menu_book_rounded,
                          onPressed: controller.reviewAnswers,
                        ),
                        const SizedBox(height: 10),
                        if (controller.canTryAgain)
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryButton(
                                  label: 'Try Again',
                                  icon: Icons.refresh_rounded,
                                  onPressed: controller.tryAgain,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SecondaryButton(
                                  label: 'Home',
                                  icon: Icons.home_outlined,
                                  onPressed: controller.goHome,
                                ),
                              ),
                            ],
                          )
                        else
                          _SecondaryButton(
                            label: 'Home',
                            icon: Icons.home_outlined,
                            onPressed: controller.goHome,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: controller.backToSubjects,
              ),
              _ShareButton(onPressed: () {}),
            ],
          ),
          // Clear the boy/trophy artwork at the top of the background image
          // so the text lands just below it.
          SizedBox(height: screenHeight * 0.16),
          const Text(
            'Quiz Completed!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFFE6DEFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              children: const [
                TextSpan(
                  text: 'Great job! You\'re one step closer to becoming a ',
                ),
                TextSpan(
                  text: 'genius! ',
                  style: TextStyle(
                    color: Color(0xFFFFD54A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: '⭐'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Share',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalScoreCard extends StatelessWidget {
  const _FinalScoreCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FINAL SCORE',
                      style: TextStyle(
                        color: Color(0xFF6B6E82),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${controller.score}',
                            style: const TextStyle(
                              color: Color(0xFF4D4FE1),
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: '/${controller.maxScore}',
                            style: const TextStyle(
                              color: Color(0xFF6B6E82),
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/star.png',
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ScoreProgressBar(
            value: controller.accuracy,
            percentLabel: '${controller.percentInt}%',
          ),
        ],
      ),
    );
  }
}

class _ScoreProgressBar extends StatelessWidget {
  const _ScoreProgressBar({required this.value, required this.percentLabel});

  final double value;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clamped = value.clamp(0.0, 1.0);
        final fullWidth = constraints.maxWidth;
        const bubbleWidth = 44.0;
        final thumbCenter = fullWidth * clamped;
        var bubbleLeft = thumbCenter - bubbleWidth / 2;
        if (bubbleLeft < 0) {
          bubbleLeft = 0;
        }
        if (bubbleLeft > fullWidth - bubbleWidth) {
          bubbleLeft = fullWidth - bubbleWidth;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: fullWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: bubbleLeft,
                    top: 0,
                    child: Container(
                      width: bubbleWidth,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D4FE1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        percentLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: clamped,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E5EC),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4D4FE1),
                    ),
                  ),
                ),
                Positioned(
                  left: (thumbCenter - 8).clamp(0.0, fullWidth - 16),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4D4FE1),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PercentageCard extends StatelessWidget {
  const _PercentageCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFF4FBF6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: controller.accuracy.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFDDF3E4),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF23A55A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Image.asset(
                    'assets/images/graph.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${controller.percentInt}%',
            style: const TextStyle(
              color: Color(0xFF1E9E57),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Percentage',
            style: TextStyle(
              color: Color(0xFF3B3D4A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _Chip(
            label: '${controller.performanceHeadline} 🎉',
            background: const Color(0xFFD7F3E1),
            textColor: const Color(0xFF1E9E57),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFFDF8F1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/target.png',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Text(
            controller.passed ? 'Well Done!' : 'Needs\nImprovement',
            style: const TextStyle(
              color: Color(0xFFE07A15),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.passed ? 'Keep it up!' : 'You can do better!',
            style: const TextStyle(
              color: Color(0xFF3B3D4A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const _Chip(
            label: 'Keep Practicing! 💪',
            background: Color(0xFFFCE9CE),
            textColor: Color(0xFFE07A15),
          ),
        ],
      ),
    );
  }
}

class _AnswersBreakdownCard extends StatelessWidget {
  const _AnswersBreakdownCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _BreakdownRow(
            iconBackground: const Color(0xFFAB63F0),
            icon: Icons.format_list_bulleted_rounded,
            label: 'Questions Attempted',
            value: '${controller.attemptedQuestions}',
            valueColor: const Color(0xFF202436),
          ),
          const Divider(height: 1, color: Color(0xFFEDEEF4)),
          _BreakdownRow(
            iconBackground: const Color(0xFF2E9BF0),
            icon: Icons.check_rounded,
            label: 'Correct Answers',
            value: '${controller.correctAnswers}',
            valueColor: const Color(0xFF1E9E57),
          ),
          const Divider(height: 1, color: Color(0xFFEDEEF4)),
          _BreakdownRow(
            iconBackground: const Color(0xFFF04848),
            icon: Icons.close_rounded,
            label: 'Wrong Answers',
            value: '${controller.wrongAnswers}',
            valueColor: const Color(0xFFF04848),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.iconBackground,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final Color iconBackground;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2C2F3E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptMetaCard extends StatelessWidget {
  const _AttemptMetaCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _MetaTile(
              imagePath: 'assets/images/questions.png',
              label: 'Questions Attempted',
              value:
                  '${controller.attemptedQuestions}/${controller.totalQuestions}',
            ),
          ),
          Container(width: 1, height: 46, color: const Color(0xFFEDEEF4)),
          Expanded(
            child: _MetaTile(
              imagePath: 'assets/images/Time.png',
              label: 'Time Taken',
              value: controller.formattedElapsedTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.imagePath,
    required this.label,
    required this.value,
  });

  final String imagePath;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Image.asset(imagePath, width: 44, height: 44, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B6E82),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF4D4FE1),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

class _LevelUpCard extends StatelessWidget {
  const _LevelUpCard({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3EEFF), Color(0xFFEDE6FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9CEFF), width: 1.4),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/rokcet.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Level Up!',
                  style: TextStyle(
                    color: Color(0xFF4D4FE1),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'You earned',
                  style: TextStyle(
                    color: Color(0xFF505165),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    controller.isLoadingXp.value
                        ? 'Calculating XP...'
                        : '+${controller.xpEarned} XP',
                    style: const TextStyle(
                      color: Color(0xFF4D4FE1),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _XpBadge(controller: controller),
        ],
      ),
    );
  }
}

class _XpBadge extends StatelessWidget {
  const _XpBadge({required this.controller});

  final QuizDailyResultController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/xp.png',
            width: 70,
            height: 70,
            fit: BoxFit.contain,
          ),
          Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.isLoadingXp.value
                      ? '...'
                      : '${controller.xpEarned}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text(
                  'XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B2CD6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: const Color(0xFF5B2CD6)),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2C2F3E),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE0DCF2), width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFDCE2F3).withValues(alpha: 0.5),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
