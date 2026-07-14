import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/appcolors.dart';

/// Custom "Update Available" dialog that matches the app's design language.
///
/// Returns `true` when the user taps **Update Now**, `false` (or `null`) when
/// they dismiss / tap **Maybe Later**.
///
/// Usage:
/// ```dart
/// final shouldUpdate = await AppUpdateDialog.show(
///   version: 'v2.1.0',
///   forceUpdate: false,
/// );
/// ```
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.version,
    required this.description,
    this.forceUpdate = false,
  });

  /// Version label shown in the pill, e.g. `v2.1.0`.
  final String version;

  /// Body copy describing the update.
  final String description;

  /// When `true` the dialog can't be dismissed and "Maybe Later" is hidden.
  final bool forceUpdate;

  static Future<bool> show({
    String version = '',
    String description =
        'A newer version of GyaanIQ Kids is ready to enhance your learning '
        'experience. Get the latest tools and performance boosts.',
    bool forceUpdate = false,
  }) async {
    final result = await Get.dialog<bool>(
      AppUpdateDialog(
        version: version,
        description: description,
        forceUpdate: forceUpdate,
      ),
      barrierDismissible: !forceUpdate,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Update Available',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (version.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildVersionBadge(),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildUpdateButton(),
                  if (!forceUpdate) ...[
                    const SizedBox(height: 6),
                    _buildLaterButton(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBright, AppColors.primary],
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.file_download_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        version,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Update Now',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.file_download_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLaterButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: () => Get.back(result: false),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Maybe Later',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
