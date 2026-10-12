import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../dashboard_vc/views/class_change_sheet.dart';
import '../controller/library_controller.dart';
import '../data/library_models.dart';
import 'library_find_views.dart';
import 'library_mine_views.dart';
import 'library_start_upload_views.dart';
import 'library_widgets.dart';

/// The Library's front door.
///
/// A student arriving here has exactly one question to answer: do I want to
/// *read* a chapter, or *give* one? So the screen offers two big doors and
/// nothing else. Search, filters, tabs and forms all live behind them — a
/// student never meets a control until it is the only thing they need.
class LibraryHomeViews extends StatefulWidget {
  const LibraryHomeViews({super.key});

  @override
  State<LibraryHomeViews> createState() => _LibraryHomeViewsState();
}

class _LibraryHomeViewsState extends State<LibraryHomeViews> {
  late final LibraryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LibraryController());
  }

  @override
  void dispose() {
    Get.delete<LibraryController>();
    super.dispose();
  }

  Future<void> _openFind() async {
    await Get.to(() => const LibraryFindViews());
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _openUpload() async {
    await Get.to(() => const LibraryStartUploadViews());
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _openMine() async {
    await Get.to(() => const LibraryMineViews());
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _pickClass() async {
    await showClassChangeSheet(context);
    await controller.refreshAfterClassChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryTopBar(title: 'Library'),
            Expanded(
              child: Obx(() {
                final meta = controller.meta.value;
                if (controller.isLoadingMeta.value && meta == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (meta == null) {
                  final status = controller.metaErrorStatus.value;
                  return LibraryMessageView(
                    icon: status == 403
                        ? Icons.lock_outline_rounded
                        : Icons.cloud_off_rounded,
                    title: status == 403
                        ? 'Library is for students'
                        : "We couldn't open the Library",
                    message: controller.metaError.value,
                    actionLabel: status == 403 ? null : 'Try again',
                    onAction: status == 403 ? null : controller.loadAll,
                  );
                }
                if (meta.classLevel == null) {
                  return LibraryMessageView(
                    icon: Icons.school_outlined,
                    title: 'Which class are you in?',
                    message:
                        'The Library shows chapters for your class. '
                        'Pick your class to start.',
                    actionLabel: 'Pick my class',
                    onAction: _pickClass,
                  );
                }
                return _doors(meta);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doors(LibraryMeta meta) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Chapters from any book',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Made by students of Class ${meta.classLevel}, for Class '
          '${meta.classLevel}.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        _BigDoor(
          icon: Icons.search_rounded,
          title: 'Find a chapter',
          subtitle: 'Read notes, questions and a quiz',
          from: const Color(0xFF3D6DF0),
          to: const Color(0xFF1C4ACB),
          onTap: _openFind,
        ),
        const SizedBox(height: 16),
        _BigDoor(
          icon: Icons.photo_camera_rounded,
          title: 'Add a chapter',
          subtitle: 'Photograph your book — we make the lesson',
          from: const Color(0xFF17A36B),
          to: const Color(0xFF0E7A4E),
          onTap: _openUpload,
        ),
        const SizedBox(height: 24),
        _MineRow(onTap: _openMine),
      ],
    );
  }
}

/// One of the two doors: a large, tappable, coloured card. Big enough that a
/// student cannot miss it, and plain enough that they know what it does.
class _BigDoor extends StatelessWidget {
  const _BigDoor({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.from,
    required this.to,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color from;
  final Color to;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [from, to],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: to.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet third way out, for the student who already started something.
class _MineRow extends StatelessWidget {
  const _MineRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LibraryPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My chapters',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'What you asked for and what you sent',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
