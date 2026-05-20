import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/learn_chapter_controller.dart';
import 'learn_chapter_views.dart';

class LearnSubjectViews extends StatefulWidget {
  const LearnSubjectViews({super.key});

  @override
  State<LearnSubjectViews> createState() => _LearnSubjectViewsState();
}

class _LearnSubjectViewsState extends State<LearnSubjectViews> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final subjects = LearnCatalogData.subjects.where((subject) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) {
        return true;
      }
      return subject.title.toLowerCase().contains(q) ||
          subject.subtitle.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Subject'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                children: [
                  const Text(
                    'Select a Subject',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Grade 8 • Path of Discovery',
                    style: TextStyle(
                      color: Color(0xFF4F5367),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search your subjects...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF72788D),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7D8092),
                        size: 22,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7C3F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7C3F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF4A4FD9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _SubjectDetailsCard(subject: subject),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LearnTopBar extends StatelessWidget {
  const LearnTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF103383),
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF103383),
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

class _SubjectDetailsCard extends StatelessWidget {
  const _SubjectDetailsCard({required this.subject});

  final LearnSubjectModel subject;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => LearnChapterViews(subject: subject)),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFC8C7F1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD6DCEF).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: subject.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(subject.icon, color: subject.accent, size: 30),
                ),
                const Spacer(),
                if (subject.statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: subject.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      subject.statusLabel!,
                      style: TextStyle(
                        color: subject.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              subject.title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subject.subtitle,
              style: const TextStyle(
                color: Color(0xFF4F5367),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject.progressText,
                    style: const TextStyle(
                      color: Color(0xFF3F4358),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  subject.progressPercentage,
                  style: TextStyle(
                    color: subject.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: subject.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE4E7EE),
                valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
