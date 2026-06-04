import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  late LearnHomeworkModel _homework;
  final List<HomeworkAttachment> _uploadedAttachments = [];
  bool _isLoadingDetail = true;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _homework = widget.homework;
    _applySubmission(_homework);
    _fetchDetail();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _applySubmission(LearnHomeworkModel homework) {
    final submission = homework.mySubmission;
    if (submission == null) {
      return;
    }
    _notesController.text = submission.textAnswer;
    _uploadedAttachments
      ..clear()
      ..addAll(submission.attachments);
  }

  Future<void> _fetchDetail() async {
    final response = await LearnHomeworkRepository.fetchHomeworkDetail(
      widget.homework.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingDetail = false;
      if (response.success && response.data != null) {
        _homework = response.data!;
        _applySubmission(_homework);
      }
    });
  }

  Future<void> _showImagePickerOptions() async {
    if (!_homework.canSubmit || _isUploading) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D7E2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                _ImageSourceTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _pickAndUploadImage(source);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1800,
        maxHeight: 1800,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final response = await LearnHomeworkRepository.uploadAttachment(
        image.path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        if (response.success && response.data != null) {
          _uploadedAttachments.add(response.data!);
        }
      });

      if (!response.success) {
        _showError(response.message);
      }
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
      });
      _showError(error.message ?? 'Unable to pick image.');
    }
  }

  Future<void> _submitHomework() async {
    final answer = _notesController.text.trim();
    if (answer.isEmpty && _uploadedAttachments.isEmpty) {
      _showError('Please add notes or upload at least one attachment.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final response = await LearnHomeworkRepository.submitHomework(
      id: _homework.id,
      textAnswer: answer,
      attachments: _uploadedAttachments,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!response.success) {
      _showError(response.message);
      return;
    }

    Get.snackbar(
      'Homework Submitted',
      '${_homework.title} has been submitted successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1D2231),
      margin: const EdgeInsets.all(14),
    );
    Get.back(result: true);
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFB42318),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homework = _homework;
    final isLocked = !homework.canSubmit;

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
                  if (_isLoadingDetail)
                    const LinearProgressIndicator(minHeight: 3),
                  if (_isLoadingDetail) const SizedBox(height: 16),
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
                    onTap: _showImagePickerOptions,
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
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF6368F2),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isUploading ? 'Uploading...' : 'Upload File',
                            style: const TextStyle(
                              color: Color(0xFF4A4FD9),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
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
                  ..._uploadedAttachments.map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AttachmentTile(
                        attachment: attachment,
                        canRemove: !isLocked,
                        onRemove: () {
                          setState(() {
                            _uploadedAttachments.remove(attachment);
                          });
                        },
                      ),
                    ),
                  ),
                  if (isLocked &&
                      homework.mySubmission?.feedback.isNotEmpty == true)
                    _FeedbackCard(feedback: homework.mySubmission!.feedback),
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
                    enabled: !isLocked,
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
                      onPressed: isLocked || _isSubmitting || _isUploading
                          ? null
                          : _submitHomework,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF4A4FD9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            isLocked
                                ? 'Graded'
                                : _isSubmitting
                                ? 'Submitting...'
                                : 'Submit Assignment',
                            style: const TextStyle(
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.canRemove,
    required this.onRemove,
  });

  final HomeworkAttachment attachment;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isPdf =
        attachment.mimeType.toLowerCase().contains('pdf') ||
        attachment.originalName.toLowerCase().endsWith('.pdf');

    return Container(
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
              color: isPdf ? const Color(0xFFFFD8D2) : const Color(0xFFE4E4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              color: isPdf ? const Color(0xFFCB2018) : const Color(0xFF4A4FD9),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.originalName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  attachment.sizeLabel,
                  style: const TextStyle(
                    color: Color(0xFF4C5164),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFCB2018),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final String feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCDEFD9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF0AA84F),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Teacher Feedback',
                style: TextStyle(
                  color: Color(0xFF0AA84F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: const TextStyle(
              color: Color(0xFF35523F),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A4FD9)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
