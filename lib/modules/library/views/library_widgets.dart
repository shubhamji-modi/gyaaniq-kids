import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../data/library_models.dart';

class LibraryPalette {
  const LibraryPalette._();

  static const Color background = Color(0xFFF7F8FD);
  static const Color accent = AppColors.primary;
  static const Color border = Color(0xFFE1E4EE);
  static const Color green = Color(0xFF17935F);
  static const Color greenSoft = Color(0xFFE3F6EC);
  static const Color amber = Color(0xFFB86E00);
  static const Color amberSoft = Color(0xFFFFF1D6);
  static const Color blue = Color(0xFF1671D9);
  static const Color blueSoft = Color(0xFFE3EEFC);
  static const Color purple = Color(0xFF6B3FD4);
  static const Color purpleSoft = Color(0xFFEDE6FF);
  static const Color red = AppColors.destructive;
  static const Color redSoft = Color(0xFFFDE4E4);
  static const Color grey = Color(0xFF8A90A2);
  static const Color greySoft = Color(0xFFEFF1F5);
}

void showLibrarySnack(String message, {bool isError = false}) {
  if (message.trim().isEmpty) return;
  Get.closeCurrentSnackbar();
  Get.rawSnackbar(
    message: message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? const Color(0xFF8E1D1D) : AppColors.textPrimary,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    borderRadius: 14,
    duration: const Duration(seconds: 4),
  );
}

/// Remaining time as the student reads it, e.g. "1 h 52 min".
String libraryDurationLabel(Duration d) {
  if (d.isNegative || d.inSeconds <= 0) return '0 min';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  if (days > 0) return hours > 0 ? '$days d $hours h' : '$days d';
  if (d.inHours > 0) {
    return minutes > 0 ? '${d.inHours} h $minutes min' : '${d.inHours} h';
  }
  return '${d.inMinutes < 1 ? 1 : d.inMinutes} min';
}

String libraryDateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final m = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'AM' : 'PM';
  return '${date.day} ${months[date.month - 1]}, $h:$m $ampm';
}

class LibraryTopBar extends StatelessWidget {
  const LibraryTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;

  /// Defaults to leaving the screen. A stepped flow passes its own handler so
  /// the arrow goes back one step first.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? Get.back,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF103383),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

class LibraryStateStyle {
  const LibraryStateStyle(this.label, this.icon, this.color, this.background);

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  static LibraryStateStyle of(LibraryLessonState state) {
    switch (state) {
      case LibraryLessonState.requested:
        return const LibraryStateStyle(
          'Waiting for OK',
          Icons.schedule_rounded,
          LibraryPalette.amber,
          LibraryPalette.amberSoft,
        );
      case LibraryLessonState.waitingForUpload:
        return const LibraryStateStyle(
          'Ready for photos',
          Icons.check_circle_outline_rounded,
          LibraryPalette.blue,
          LibraryPalette.blueSoft,
        );
      case LibraryLessonState.youCanUpload:
        return const LibraryStateStyle(
          'Needs photos',
          Icons.photo_camera_outlined,
          LibraryPalette.green,
          LibraryPalette.greenSoft,
        );
      case LibraryLessonState.yourUploadInProgress:
        return const LibraryStateStyle(
          'You are doing this',
          Icons.cloud_upload_outlined,
          AppColors.primary,
          AppColors.primaryLight,
        );
      case LibraryLessonState.beingUploaded:
        return const LibraryStateStyle(
          'Someone is doing this',
          Icons.cloud_upload_outlined,
          LibraryPalette.blue,
          LibraryPalette.blueSoft,
        );
      case LibraryLessonState.yourUploadInReview:
      case LibraryLessonState.inReview:
        return const LibraryStateStyle(
          'Being checked',
          Icons.hourglass_top_rounded,
          LibraryPalette.purple,
          LibraryPalette.purpleSoft,
        );
      case LibraryLessonState.available:
        return const LibraryStateStyle(
          'Ready to read',
          Icons.menu_book_rounded,
          LibraryPalette.green,
          LibraryPalette.greenSoft,
        );
      case LibraryLessonState.unavailable:
        return const LibraryStateStyle(
          'Not open',
          Icons.block_rounded,
          LibraryPalette.grey,
          LibraryPalette.greySoft,
        );
      case LibraryLessonState.rejected:
        return const LibraryStateStyle(
          'Not allowed',
          Icons.cancel_outlined,
          LibraryPalette.red,
          LibraryPalette.redSoft,
        );
      case LibraryLessonState.unknown:
        return const LibraryStateStyle(
          'Waiting',
          Icons.more_horiz_rounded,
          LibraryPalette.grey,
          LibraryPalette.greySoft,
        );
    }
  }
}

class LibraryStateBadge extends StatelessWidget {
  const LibraryStateBadge({super.key, required this.state});

  final LibraryLessonState state;

  @override
  Widget build(BuildContext context) {
    final style = LibraryStateStyle.of(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryPrimaryButton extends StatelessWidget {
  const LibraryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = false,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
    final button = ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class LibrarySecondaryButton extends StatelessWidget {
  const LibrarySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = false,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.55)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Full-area message: errors, empty lists, "pick your class", 403s.
class LibraryMessageView extends StatelessWidget {
  const LibraryMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.scrollable = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(icon, color: const Color(0xFF9AA0B0), size: 54),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (message.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7080),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 20),
        Center(
          child: LibrarySecondaryButton(
            label: actionLabel!,
            onPressed: onAction,
          ),
        ),
      ],
    ];
    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 80, 30, 30),
      children: children,
    );
  }
}

/// One lesson in a list. What it offers comes straight from the server's
/// `myState` + `message` — nothing is worked out on the device.
class LibraryLessonCard extends StatelessWidget {
  const LibraryLessonCard({
    super.key,
    required this.lesson,
    required this.uploadsAvailable,
    required this.followBusy,
    required this.onOpen,
    required this.onRead,
    required this.onUpload,
    required this.onContinue,
    required this.onToggleFollow,
  });

  final LibraryLesson lesson;
  final bool uploadsAvailable;
  final bool followBusy;
  final VoidCallback onOpen;
  final VoidCallback onRead;
  final VoidCallback onUpload;
  final VoidCallback onContinue;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final state = lesson.myState;
    final disabled = state == LibraryLessonState.unavailable;
    final style = LibraryStateStyle.of(state);
    final showMessage =
        lesson.message.isNotEmpty && state != LibraryLessonState.available;

    final actions = _actions();

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: disabled ? null : onOpen,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LibraryPalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: style.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lesson.chapterNumber}',
                          style: TextStyle(
                            color: style.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.sourceLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              lesson.title.isEmpty ? 'Untitled' : lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      LibraryStateBadge(state: state),
                    ],
                  ),
                  if (showMessage) ...[
                    const SizedBox(height: 10),
                    Text(
                      lesson.message,
                      style: TextStyle(
                        color: state == LibraryLessonState.rejected
                            ? LibraryPalette.red
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (state == LibraryLessonState.yourUploadInReview) ...[
                    const SizedBox(height: 8),
                    const _InfoLine(
                      icon: Icons.info_outline_rounded,
                      text:
                          'Your class will see this once a teacher checks it.',
                    ),
                  ],
                  if (state == LibraryLessonState.youCanUpload &&
                      !uploadsAvailable) ...[
                    const SizedBox(height: 8),
                    const _InfoLine(
                      icon: Icons.cloud_off_rounded,
                      text: 'Photos are paused right now. Please try later.',
                    ),
                  ],
                  if (lesson.followerCount > 0 &&
                      state != LibraryLessonState.available) ...[
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.groups_2_outlined,
                      text: lesson.followerCount == 1
                          ? '1 student is waiting for this'
                          : '${lesson.followerCount} students are waiting for this',
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actions() {
    final state = lesson.myState;
    final out = <Widget>[];

    switch (state) {
      case LibraryLessonState.available:
      case LibraryLessonState.yourUploadInReview:
        out.add(
          LibraryPrimaryButton(
            label: 'Read it',
            icon: Icons.chrome_reader_mode_outlined,
            onPressed: onRead,
          ),
        );
      case LibraryLessonState.youCanUpload:
        if (uploadsAvailable) {
          out.add(
            LibraryPrimaryButton(
              label: 'Take photos',
              icon: Icons.photo_camera_outlined,
              onPressed: onUpload,
              color: LibraryPalette.green,
            ),
          );
        }
      case LibraryLessonState.yourUploadInProgress:
        out.add(
          LibraryPrimaryButton(
            label: 'Carry on',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        );
      default:
        break;
    }

    if (state.offersFollow) {
      if (!lesson.isFollowing) {
        out.add(
          LibrarySecondaryButton(
            label: "Tell me when it's ready",
            icon: Icons.notifications_none_rounded,
            busy: followBusy,
            onPressed: onToggleFollow,
          ),
        );
      } else {
        out.add(
          LibrarySecondaryButton(
            label: 'Pending from admin',
            icon: Icons.notifications_active_rounded,
            busy: followBusy,
            color: LibraryPalette.green,
            // The requester always follows their own request.
            onPressed: lesson.isRequester ? null : onToggleFollow,
          ),
        );
      }
    }
    return out;
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small "4 of 5 left today" pill.
class LibraryQuotaPill extends StatelessWidget {
  const LibraryQuotaPill({
    super.key,
    required this.icon,
    required this.label,
    required this.quota,
  });

  final IconData icon;
  final String label;
  final LibraryQuotaItem quota;

  @override
  Widget build(BuildContext context) {
    final out = quota.remaining <= 0;
    final color = out ? LibraryPalette.red : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: out ? LibraryPalette.redSoft : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label ${quota.remaining}/${quota.limit}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared field decoration for every Library form.
InputDecoration libraryInputDecoration({required String hint, String? error}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted6),
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: border(LibraryPalette.border),
    focusedBorder: border(AppColors.primary),
    errorBorder: border(LibraryPalette.red),
    focusedErrorBorder: border(LibraryPalette.red),
  );
}

/// "Step 2 of 3" plus the question being asked, over a bar that fills up.
/// Shared by every stepped Library flow so they all feel like one thing.
class LibraryStepBar extends StatelessWidget {
  const LibraryStepBar({
    super.key,
    required this.step,
    required this.total,
    this.label,
  });

  final int step;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of $total',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 3),
            Text(
              label!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? AppColors.primary
                          : LibraryPalette.greySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i != total) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
