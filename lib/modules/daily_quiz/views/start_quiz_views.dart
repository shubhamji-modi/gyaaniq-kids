import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/start_quiz_controller.dart';

class StartQuizViews extends StatelessWidget {
  const StartQuizViews({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StartQuizController>()
        ? Get.find<StartQuizController>()
        : Get.put(StartQuizController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const _QuizTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFAB1D),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        controller.challengeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      controller.title,
                      style: const TextStyle(
                        color: Color(0xFF4950DB),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      controller.description,
                      style: const TextStyle(
                        color: Color(0xFF474B5F),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      controller.meta,
                      style: const TextStyle(
                        color: Color(0xFF474B5F),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.startQuiz,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Start Quiz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D4FE1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _FeatureCard(data: controller.features[0]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FeatureCard(data: controller.features[1]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _WideFeatureCard(data: controller.features[2]),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD8E0F3).withValues(alpha: 0.75),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF5F6FF)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quiz Instructions',
                            style: TextStyle(
                              color: Color(0xFF4950DB),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(controller.instructions.length, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == controller.instructions.length - 1 ? 0 : 18,
                              ),
                              child: _InstructionTile(
                                number: index + 1,
                                text: controller.instructions[index],
                              ),
                            );
                          }),
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

class _QuizTopBar extends StatelessWidget {
  const _QuizTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
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
                fontSize: 24,
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final QuizFeatureData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD5D3F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDFE5F5).withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: data.title == 'AI Assistance'
                  ? const Color(0xFFF1D9FF)
                  : const Color(0xFFD8D6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.title == 'AI Assistance'
                  ? const Color(0xFF8B36D9)
                  : const Color(0xFF4A4FD9),
              size: 22,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.title,
            style: const TextStyle(
              color: Color(0xFF1D2230),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: const TextStyle(
              color: Color(0xFF4B4E63),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _WideFeatureCard extends StatelessWidget {
  const _WideFeatureCard({required this.data});

  final QuizFeatureData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD5D3F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDFE5F5).withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDBAB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: const Color(0xFF9C6200),
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF1D2230),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.description,
                  style: const TextStyle(
                    color: Color(0xFF4B4E63),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.8,
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

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: Color(0xFF4D4FE1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF212538),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
