import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/data/class_catalogue.dart';
import '../../../core/data/user_profile_provider.dart';
import '../../../core/service/api_service.dart';
import '../../../core/theme/appcolors.dart';

/// Bottom sheet that lets a student change their class from the dashboard.
///
/// Fetches [ClassCatalogueRepository.fetchActiveClasses] on open, shows the
/// current class pre-selected, and submits via the same
/// `PUT user/profile/setup` endpoint used by full profile edits — sending the
/// existing profile fields alongside the new `classLevel` so other fields are
/// left untouched. The backend enforces the `classChangeByUser` policy
/// (e.g. rejecting an already-set class change with 403), so failures are
/// surfaced as-is rather than re-validated on the client.
Future<void> showClassChangeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _ClassChangeSheet(),
  );
}

class _ClassChangeSheet extends StatefulWidget {
  const _ClassChangeSheet();

  @override
  State<_ClassChangeSheet> createState() => _ClassChangeSheetState();
}

class _ClassChangeSheetState extends State<_ClassChangeSheet> {
  bool _loading = true;
  bool _submitting = false;
  String _error = '';
  List<ClassOption> _classes = const [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = context.read<UserProfileProvider>().profile?.userClass;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final response = await ClassCatalogueRepository.fetchActiveClasses();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success) {
        _classes = response.data ?? const [];
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _submit() async {
    final provider = context.read<UserProfileProvider>();
    final currentProfile = provider.profile;
    final selected = _selectedClass;
    if (currentProfile == null || selected == null || _submitting) {
      return;
    }

    setState(() => _submitting = true);

    final response = await ApiService.instance.put<dynamic>(
      endpoint: ApiService.EDIT_PROFILE,
      data: {...currentProfile.toProfilePayload(), 'classLevel': selected},
      fromJson: (json) => json,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final body = response.data;
    final message = body is Map<String, dynamic>
        ? body['message']?.toString() ?? response.message
        : response.message;

    if (!response.success) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    provider.setProfile(currentProfile.copyWith(userClass: selected));

    if (!mounted) return;
    Navigator.pop(context);
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B8A5A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _ink = AppColors.textPrimary;
  static const Color _muted = AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E3EE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildHeader(),
          const SizedBox(height: 28),
          _buildSectionLabel(),
          const SizedBox(height: 14),
          _buildBody(),
          const SizedBox(height: 10),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel() {
    final currentClass = context.read<UserProfileProvider>().profile?.userClass;
    return Row(
      children: [
        const Text(
          'AVAILABLE CLASSES',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        if (currentClass != null && currentClass.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Current: $currentClass',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryBright, _primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Class',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pick the class you are studying in',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF6B6E80),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final currentClass = context.read<UserProfileProvider>().profile?.userClass;
    final unchanged = _selectedClass == currentClass;
    final enabled = _selectedClass != null && !_submitting && !unchanged;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? _submit : null,
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primaryBright, _primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unchanged ? 'Already in this class' : 'Save Changes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!unchanged) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD5D1)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFB42318),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9A2F2F),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: _primary),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No classes available right now.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final currentClass = context.read<UserProfileProvider>().profile?.userClass;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _classes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final option = _classes[index];
        return _ClassCard(
          label: option.className,
          palette: _ClassPalette.forIndex(index),
          selected: _selectedClass == option.className,
          isCurrent: currentClass == option.className,
          onTap: () => setState(() => _selectedClass = option.className),
        );
      },
    );
  }
}

/// One accent colour per class card so the grid reads as a playful,
/// colourful picker instead of a wall of identical grey chips.
class _ClassPalette {
  const _ClassPalette({
    required this.tint,
    required this.accent,
    required this.gradientEnd,
  });

  /// Soft background used when the card is not selected.
  final Color tint;

  /// Strong colour used for the number text, dot and selected gradient start.
  final Color accent;

  /// Darker end of the gradient shown when selected.
  final Color gradientEnd;

  static const List<_ClassPalette> _all = [
    _ClassPalette(
      tint: AppColors.primaryLight,
      accent: AppColors.primary,
      gradientEnd: AppColors.primaryDark,
    ),
    _ClassPalette(
      tint: AppColors.purpleSoft,
      accent: AppColors.purple,
      gradientEnd: AppColors.purpleDark,
    ),
    _ClassPalette(
      tint: AppColors.streakBackground,
      accent: AppColors.streakIcon,
      gradientEnd: AppColors.streakText,
    ),
    _ClassPalette(
      tint: Color(0xFFE8F8EE),
      accent: AppColors.success,
      gradientEnd: Color(0xFF15803D),
    ),
    _ClassPalette(
      tint: AppColors.blueGrayLight,
      accent: AppColors.avatarBorder,
      gradientEnd: AppColors.avatarGradientStart,
    ),
    _ClassPalette(
      tint: AppColors.purpleSoft2,
      accent: AppColors.purpleDark,
      gradientEnd: AppColors.purpleLabel,
    ),
    _ClassPalette(
      tint: AppColors.primaryPale,
      accent: AppColors.primaryScore,
      gradientEnd: AppColors.textBlueDark,
    ),
  ];

  static _ClassPalette forIndex(int index) => _all[index % _all.length];
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.label,
    required this.palette,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final _ClassPalette palette;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  /// Splits "10th" into ("10", "th") so the suffix can render smaller.
  (String, String) _split() {
    final match = RegExp(r'^(\d+)(.*)$').firstMatch(label.trim());
    if (match == null) return (label, '');
    return (match.group(1)!, match.group(2)!);
  }

  @override
  Widget build(BuildContext context) {
    final (number, suffix) = _split();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.accent, palette.gradientEnd],
                  )
                : null,
            color: selected ? null : palette.tint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : palette.accent.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.38),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: number,
                        style: TextStyle(
                          color: selected ? Colors.white : palette.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: suffix,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.85)
                              : palette.accent.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: palette.gradientEnd,
                    ),
                  ),
                )
              else if (isCurrent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
