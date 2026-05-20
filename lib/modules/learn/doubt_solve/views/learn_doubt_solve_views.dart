import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import 'learn_doubt_solve_teacher_views.dart';

class LearnDoubtSolveViews extends StatelessWidget {
  const LearnDoubtSolveViews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Doubt Solve'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  const _LockedHelpCard(
                    icon: Icons.auto_awesome_outlined,
                    iconBackground: Color(0xFFDAD8FF),
                    iconColor: Color(0xFF4A4FD9),
                    title: 'Instant AI Tutor',
                    subtitle:
                        'Get step-by-step help in seconds. Best for quick explanations.',
                    buttonLabel: 'Chat with AI',
                  ),
                  const SizedBox(height: 18),
                  _TeacherHelpCard(
                    onTap: () =>
                        Get.to(() => const LearnDoubtSolveTeacherViews()),
                  ),
                  const SizedBox(height: 18),
                  const _LockedQuickQuestionCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedHelpCard extends StatelessWidget {
  const _LockedHelpCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.62,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E5EE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD6DCEF).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: iconBackground,
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4C5164),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4FD9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 15,
            right: 15,
            child: _LockBadge(),
          ),
        ],
      ),
    );
  }
}

class _TeacherHelpCard extends StatelessWidget {
  const _TeacherHelpCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E5EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD6DCEF).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEBD2FF),
            child: Icon(
              Icons.school_outlined,
              color: Color(0xFF7D31E2),
              size: 28,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Connect with Teacher',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get a detailed solution from a real subject expert. Best for complex concepts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4C5164),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B2CE2), Color(0xFF7D31E2)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Ask a Teacher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedQuickQuestionCard extends StatelessWidget {
  const _LockedQuickQuestionCard();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.58,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E5EE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask a quick question',
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Type your question here...',
                          style: TextStyle(
                            color: Color(0xFF7C8092),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A4FD9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF7C8092),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Scan',
                      style: TextStyle(
                        color: Color(0xFF7C8092),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 24),
                    Icon(
                      Icons.mic_none_rounded,
                      color: Color(0xFF7C8092),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Voice',
                      style: TextStyle(
                        color: Color(0xFF7C8092),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            top: 18,
            right: 18,
            child: _LockBadge(),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2231).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Locked',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
