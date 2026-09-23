import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/user_profile_provider.dart';
import '../../../../core/service/api_service.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileViews extends StatefulWidget {
  const EditProfileViews({super.key});

  @override
  State<EditProfileViews> createState() => _EditProfileViewsState();
}

class _EditProfileViewsState extends State<EditProfileViews> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final ImagePicker _imagePicker = ImagePicker();

  /// The student's class, shown in the locked "Current Grade" field. It is
  /// display-only — this screen never changes the class, so it is always
  /// mirrored straight from the profile and sent back untouched.
  String _currentGrade = '';
  String _profilePic = '';
  File? _selectedImageFile;
  bool _isSaving = false;

  final _otpFormKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _otpTimer;
  StateSetter? _otpSheetSetState;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _otpRemainingSeconds = 0;
  String _verifyingPhone = '';

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().profile;
    final profileName = profile?.name ?? 'Alex Johnson';

    _nameController = TextEditingController(text: profileName);
    _phoneController = TextEditingController(text: profile?.mobile ?? '');
    // Never coerced onto a hard-coded grade list: a class the list did not
    // know about used to be rewritten here and then saved back, silently
    // switching the student's class when they only edited their photo.
    _currentGrade = profile?.userClass.trim() ?? '';
    _profilePic = profile?.profilePic ?? '';
  }

  Future<void> _showImagePickerOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ProfilePhotoSheet(
          currentProfilePic: _profilePic,
          onAvatarSelected: _onAvatarSelected,
        );
      },
    );

    if (source == null) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _pickProfileImage(source);
  }

  /// Called when a library avatar is picked. The Select API has already set the
  /// profile picture server-side; here we mirror it locally and into the shared
  /// [UserProfileProvider] so it shows everywhere the profile photo appears.
  void _onAvatarSelected(String url) {
    if (!mounted || url.trim().isEmpty) {
      return;
    }
    final provider = context.read<UserProfileProvider>();
    final current = provider.profile;
    if (current != null) {
      provider.setProfile(current.copyWith(profilePic: url));
    }
    setState(() {
      _profilePic = url;
      _selectedImageFile = null;
    });
    _showMessage('Avatar updated successfully.');
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImageFile = File(image.path);
        _profilePic = image.path;
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      final message = _pickerErrorMessage(error);
      _showMessage(message, isError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to pick image. Please try again.', isError: true);
    }
  }

  String _pickerErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') || code.contains('denied')) {
      return 'Photo permission is denied. Please allow photo access from Settings.';
    }
    if (code.contains('camera')) {
      return 'Camera is not available on this device.';
    }
    if (code.contains('missingplugin')) {
      return 'Please restart the app once, then try again.';
    }
    return error.message?.trim().isNotEmpty == true
        ? error.message!
        : 'Unable to pick image. Please try again.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    var local = digits;
    if (local.length == 12 && local.startsWith('91')) {
      local = local.substring(2);
    } else if (local.length == 11 && local.startsWith('0')) {
      local = local.substring(1);
    }
    if (local.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (local.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(local)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  String? _validateOtpDigit(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return '';
    }
    return null;
  }

  String get _otpCode => _otpControllers.map((field) => field.text).join();

  String get _otpTime {
    final minutes = (_otpRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedVerifyingPhone {
    final digits = _verifyingPhone.replaceAll(RegExp(r'\D'), '');
    final local = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    if (local.length < 4) {
      return '+91 $local';
    }
    return '+91 •••• ${local.substring(local.length - 4)}';
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpRemainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _otpRemainingSeconds--);
      _rebuildOtpSheet();
    });
  }

  void _rebuildOtpSheet() {
    _otpSheetSetState?.call(() {});
  }

  Future<void> _startPhoneVerification() async {
    if (_isSendingOtp) {
      return;
    }
    final phoneError = _validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      _showMessage(phoneError, isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSendingOtp = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.PHONE_VERIFICATION_SEND_OTP,
      data: {'phone': _phoneController.text.trim()},
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isSendingOtp = false);

    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = _asStringKeyMap(body['data']);
    final resendAfterSeconds =
        int.tryParse(data?['resendAfterSeconds']?.toString() ?? '') ?? 60;

    for (final controller in _otpControllers) {
      controller.clear();
    }
    _verifyingPhone = _phoneController.text.trim();
    _otpRemainingSeconds = resendAfterSeconds;
    _startOtpTimer();
    _showMessage(body['message']?.toString() ?? 'OTP sent successfully');
    await _showOtpBottomSheet();
  }

  Future<void> _verifyPhoneOtp() async {
    if (_isVerifyingOtp) {
      return;
    }

    final form = _otpFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isVerifyingOtp = true);
    _rebuildOtpSheet();

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.PHONE_VERIFICATION_VERIFY,
      data: {'phone': _verifyingPhone, 'otp': _otpCode},
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isVerifyingOtp = false);
    _rebuildOtpSheet();

    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = _asStringKeyMap(body['data']);
    final verifiedPhone = data?['phoneNumber']?.toString() ?? _verifyingPhone;

    final provider = context.read<UserProfileProvider>();
    final current = provider.profile;
    if (current != null) {
      provider.setProfile(current.copyWith(mobile: verifiedPhone));
    }
    setState(() {
      _phoneController.text = verifiedPhone;
    });

    _otpTimer?.cancel();
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _showMessage(
      body['message']?.toString() ?? 'Phone number verified successfully',
    );
  }

  void _closeOtpSheet(BuildContext sheetContext) {
    _otpTimer?.cancel();
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }
  }

  Future<void> _showOtpBottomSheet() async {
    if (!mounted) {
      return;
    }

    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            _otpSheetSetState = sheetSetState;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: _buildPhoneOtpVerification(theme, context),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _otpSheetSetState = null;
      _otpTimer?.cancel();
    });
  }

  Widget _buildPhoneOtpVerification(ThemeData theme, BuildContext sheetContext) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('phone-otp'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD8DCEB),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Verify Phone',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF191B24),
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a 6-digit code to $_maskedVerifyingPhone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF555B6D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please enter it below to continue.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF555B6D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(right: index == 5 ? 0 : 9),
                child: _ProfileOtpBox(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  validator: _validateOtpDigit,
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Did not receive the code?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF343846),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_otpRemainingSeconds > 0) ...[
                Text(
                  'Resend Code ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _otpTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ] else
                GestureDetector(
                  onTap: _isSendingOtp
                      ? null
                      : () async {
                          Navigator.of(sheetContext).pop();
                          await _startPhoneVerification();
                        },
                  child: Text(
                    'Resend Code',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 34),
          _ProfileActionButton(
            label: 'Verify Phone',
            isLoading: _isVerifyingOtp,
            onPressed: _isVerifyingOtp ? null : _verifyPhoneOtp,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isVerifyingOtp
                ? null
                : () => _closeOtpSheet(sheetContext),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> _saveProfile() async {
    final provider = context.read<UserProfileProvider>();
    final currentProfile = provider.profile;
    final updatedName = _nameController.text.trim().isEmpty
        ? 'Student'
        : _nameController.text.trim();
    if (currentProfile == null) {
      _showMessage('Profile data not found', isError: true);
      return;
    }

    final profilePicPayload = await _buildProfilePicPayload();
    if (!mounted || profilePicPayload == _invalidProfilePicPayload) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final response = await ApiService.instance.put<dynamic>(
      endpoint: ApiService.EDIT_PROFILE,
      data: {
        'name': updatedName,
        'instructionMedium': currentProfile.instructionMedium,
        // Echoed back from the stored profile, never from local UI state, so
        // this screen can never change the class as a side effect.
        'classLevel': currentProfile.userClass,
        'educationalBoard': currentProfile.educationBoard,
        'profilePic': profilePicPayload,
      },
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      _showMessage(
        body['message']?.toString() ?? 'Profile update failed',
        isError: true,
      );
      return;
    }

    final apiProfile = UserProfile.fromApi(data);
    provider.setProfile(
      apiProfile.copyWith(
        mobile: _phoneController.text.trim(),
        profilePic: apiProfile.profilePic.isEmpty
            ? _profilePic.trim()
            : apiProfile.profilePic,
      ),
    );

    _showMessage(
      body['message']?.toString() ??
          'Your profile changes have been saved successfully.',
    );
  }

  static const String _invalidProfilePicPayload = '__invalid_profile_pic__';

  Future<String?> _buildProfilePicPayload() async {
    final selectedFile = _selectedImageFile;
    if (selectedFile == null) {
      final currentValue = _profilePic.trim();
      return currentValue.isEmpty ? null : currentValue;
    }

    try {
      final bytes = await selectedFile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Image is too large. Max 5 MB allowed.', isError: true);
        return _invalidProfilePicPayload;
      }

      final mimeType = _imageMimeType(selectedFile.path);
      if (mimeType == null) {
        _showMessage(
          'Unsupported image type. Please choose JPEG, PNG, WEBP, or GIF.',
          isError: true,
        );
        return _invalidProfilePicPayload;
      }

      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    } catch (_) {
      _showMessage(
        'Unable to prepare profile picture. Please try again.',
        isError: true,
      );
      return _invalidProfilePicPayload;
    }
  }

  String? _imageMimeType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerPath.endsWith('.gif')) {
      return 'image/gif';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFB42318)
          : const Color(0xFF0F9D58),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;
    final displayName = _nameController.text.trim().isEmpty
        ? (profile?.name ?? 'Alex Johnson')
        : _nameController.text.trim();
    final email = profile?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const _EditProfileTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  children: [
                    _ProfileHeader(
                      name: displayName,
                      profilePic: _profilePic,
                      selectedImageFile: _selectedImageFile,
                      onCameraTap: _showImagePickerOptions,
                    ),
                    const SizedBox(height: 28),
                    _SectionCard(
                      title: 'Personal Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(title: 'Full Name'),
                          _InputField(controller: _nameController),
                          const SizedBox(height: 22),
                          const _FieldLabel(title: 'Email Address (Primary)'),
                          _ReadOnlyField(
                            value: email.isEmpty ? 'Not available' : email,
                            trailing: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF7B7C91),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _FieldLabel(title: 'Phone Number'),
                          _PhoneNumberField(
                            controller: _phoneController,
                            hasVerifiedNumber:
                                (profile?.mobile.trim() ?? '').isNotEmpty,
                            isSending: _isSendingOtp,
                            onVerifyTap: _startPhoneVerification,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Academic Path',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(title: 'Current Grade'),
                          _ReadOnlyField(
                            value: _currentGrade.isEmpty ? '-' : _currentGrade,
                            trailing: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF7B7C91),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFF4B49E3),
                          foregroundColor: Colors.white,
                          shadowColor: const Color(
                            0xFF4B49E3,
                          ).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(42),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSaving ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF7B7C91),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Premium Member since 2026',
                          style: TextStyle(
                            color: Color(0xFF7B7C91),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
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

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar();

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
              color: Color(0xFF4B49E3),
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B49E3),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.profilePic,
    required this.selectedImageFile,
    required this.onCameraTap,
  });

  final String name;
  final String profilePic;
  final File? selectedImageFile;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final trimmedProfilePic = profilePic.trim();
    final localImage =
        selectedImageFile ??
        (trimmedProfilePic.isNotEmpty && !trimmedProfilePic.startsWith('http')
            ? File(trimmedProfilePic)
            : null);
    final networkImage = trimmedProfilePic.startsWith('http')
        ? trimmedProfilePic
        : '';

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 130,
              height: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF4F6FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCDD5EA).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF7A30), width: 2),
                ),
                child: ClipOval(
                  child: localImage != null
                      ? Image.file(
                          localImage,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : networkImage.isNotEmpty
                      ? Image.network(
                          networkImage,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ProfileFallbackIcon(),
                        )
                      : const _ProfileFallbackIcon(),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 4,
              child: GestureDetector(
                onTap: onCameraTap,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4B49E3),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF45475B),
            fontSize: 16,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProfileFallbackIcon extends StatelessWidget {
  const _ProfileFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      backgroundColor: Color(0xFFFFD0AF),
      child: Icon(Icons.person_rounded, size: 45, color: Color(0xFF7D4B2C)),
    );
  }
}

/// Bottom sheet that offers the admin avatar library (API-backed, paginated)
/// plus the Camera / Gallery sources.
class _ProfilePhotoSheet extends StatefulWidget {
  const _ProfilePhotoSheet({
    required this.currentProfilePic,
    required this.onAvatarSelected,
  });

  final String currentProfilePic;
  final void Function(String url) onAvatarSelected;

  @override
  State<_ProfilePhotoSheet> createState() => _ProfilePhotoSheetState();
}

class _ProfilePhotoSheetState extends State<_ProfilePhotoSheet> {
  static const int _pageSize = 24;

  final ScrollController _scrollController = ScrollController();
  final List<AvatarItem> _avatars = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 0;
  String _error = '';
  String? _selectingId;
  late String _selectedUrl;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.currentProfilePic.trim();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final response = await EditProfileAvatarRepository.fetchAvatars(
      page: 1,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        final page = response.data!;
        _avatars
          ..clear()
          ..addAll(page.avatars);
        _page = page.page;
        _hasMore = page.hasMore;
      } else {
        _error = response.message;
        _hasMore = false;
      }
    });
  }

  Future<void> _loadNextPage() async {
    setState(() => _loadingMore = true);
    final response = await EditProfileAvatarRepository.fetchAvatars(
      page: _page + 1,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (response.success && response.data != null) {
        final page = response.data!;
        _avatars.addAll(page.avatars);
        _page = page.page;
        _hasMore = page.hasMore;
      } else {
        _hasMore = false;
      }
    });
  }

  Future<void> _selectAvatar(AvatarItem avatar) async {
    if (_selectingId != null) return;
    setState(() => _selectingId = avatar.id);
    final response = await EditProfileAvatarRepository.selectAvatar(avatar.id);
    if (!mounted) return;
    setState(() => _selectingId = null);

    if (response.success) {
      final url = (response.data ?? '').isNotEmpty ? response.data! : avatar.url;
      widget.onAvatarSelected(url);
      Navigator.pop(context);
    } else {
      Get.snackbar(
        'Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D7E2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Avatar Library',
              style: TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select your character',
              style: TextStyle(
                color: Color(0xFF7B7C91),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(height: 100, child: _buildAvatarRow()),
            // Camera/Gallery are intentionally hidden: the profile photo can
            // only come from the admin-managed avatar library above.
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarRow() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B49E3)),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _error,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A2F2F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(onPressed: _loadFirstPage, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_avatars.isEmpty) {
      return const Center(
        child: Text(
          'No avatars yet. Ask your admin to add some!',
          style: TextStyle(
            color: Color(0xFF7B7C91),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: _avatars.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _avatars.length) {
          return const SizedBox(
            width: 60,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B49E3)),
                ),
              ),
            ),
          );
        }
        final avatar = _avatars[index];
        return _AvatarTile(
          avatar: avatar,
          selected: _selectedUrl.isNotEmpty && _selectedUrl == avatar.url,
          loading: _selectingId == avatar.id,
          onTap: () => _selectAvatar(avatar),
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final AvatarItem avatar;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 84,
          padding: EdgeInsets.all(selected ? 3 : 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4B49E3)
                  : const Color(0xFFE4E6F1),
              width: selected ? 3 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  avatar.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const ColoredBox(
                      color: Color(0xFFEDEFFA),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4B49E3),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const ColoredBox(
                    color: Color(0xFFEDEFFA),
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF9BA1C4),
                      size: 30,
                    ),
                  ),
                ),
                if (loading)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (selected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B49E3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2D8E7).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF787A8F),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.keyboardType,
    this.hintText,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF1D2231),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F8),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFADB3C1),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF4B49E3), width: 1.5),
        ),
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.controller,
    required this.hasVerifiedNumber,
    required this.isSending,
    required this.onVerifyTap,
  });

  final TextEditingController controller;
  final bool hasVerifiedNumber;
  final bool isSending;
  final VoidCallback onVerifyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !hasVerifiedNumber,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              LengthLimitingTextInputFormatter(18),
            ],
            style: TextStyle(
              color: hasVerifiedNumber
                  ? const Color(0xFF7B7C91)
                  : const Color(0xFF1D2231),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F8),
              hintText: 'Enter phone number',
              hintStyle: const TextStyle(
                color: Color(0xFFADB3C1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              suffixIcon: hasVerifiedNumber
                  ? const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF12B76A),
                      size: 20,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFF4B49E3),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        if (!hasVerifiedNumber) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSending ? null : onVerifyTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF4B49E3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileOtpBox extends StatelessWidget {
  const _ProfileOtpBox({
    required this.controller,
    required this.focusNode,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 52,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          color: Color(0xFF4F46E5),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD8DCEB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD8DCEB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD92D20)),
          ),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(
              0xFF4F46E5,
            ).withValues(alpha: 0.65),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, this.trailing});

  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF7B7C91),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
