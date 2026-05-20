import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_homework_controller.dart';

class LearnHomeworkSumbitViews extends StatefulWidget {
  const LearnHomeworkSumbitViews({super.key, required this.homework});

  final LearnHomeworkModel homework;

  @override
  State<LearnHomeworkSumbitViews> createState() =>
      _LearnHomeworkSumbitViewsState();
}

class _LearnHomeworkSumbitViewsState extends State<LearnHomeworkSumbitViews> {
  final TextEditingController _notesController = TextEditingController();
  bool _hasFile = true;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homework = widget.homework;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Homework'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFC8C7F1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HeaderChip(
                              label: homework.subject,
                              background: const Color(0xFFE4E4FF),
                              foreground: const Color(0xFF4A4FD9),
                            ),
                            _HeaderChip(
                              label: homework.readTime,
                              background: const Color(0xFFFFDFB7),
                              foreground: const Color(0xFF8A5A00),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          homework.title,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF4C5164),
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Deadline: ${homework.dueDate}',
                              style: const TextStyle(
                                color: Color(0xFF4C5164),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F8),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE1E4EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF4A4FD9),
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'INSTRUCTIONS',
                              style: TextStyle(
                                color: Color(0xFF4A4FD9),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          homework.instructions,
                          style: const TextStyle(
                            color: Color(0xFF4C5164),
                            fontSize: 14,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Submission',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasFile = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFBDC3FF),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: const Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFF6368F2),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Upload File',
                            style: TextStyle(
                              color: Color(0xFF4A4FD9),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'PDF, JPG, or PNG, Max 10MB',
                            style: TextStyle(
                              color: Color(0xFF4C5164),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_hasFile)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFC8C7F1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD8D2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: Color(0xFFCB2018),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  homework.fileName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1D2231),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  homework.fileMeta,
                                  style: const TextStyle(
                                    color: Color(0xFF4C5164),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _hasFile = false;
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFCB2018),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Text(
                    'Additional Notes',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Leave a message for your teacher...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFA0A3B1),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFC8C7F1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFC8C7F1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFF4A4FD9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.snackbar(
                          'Homework Submitted',
                          '${homework.title} has been submitted successfully.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                          colorText: const Color(0xFF1D2231),
                          margin: const EdgeInsets.all(14),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF4A4FD9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 12),
                          Text(
                            'Submit Assignment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'By submitting, you agree to the Lumina\nAcademic Honesty Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4C5164),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
