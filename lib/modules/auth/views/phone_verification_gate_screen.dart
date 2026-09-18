import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/data/user_profile_provider.dart';
import '../../../core/service/api_service.dart';
import '../../../routes/app_routes.dart';

/// Mandatory phone-verification screen shown when `user/profile` has no
/// mobile number on file. Blocks all navigation (back button included)
/// until the user sends and verifies an OTP for a phone number.
class PhoneVerificationGateScreen extends StatefulWidget {
  const PhoneVerificationGateScreen({super.key});

  @override
  State<PhoneVerificationGateScreen> createState() =>
      _PhoneVerificationGateScreenState();
}

class _PhoneVerificationGateScreenState
    extends State<PhoneVerificationGateScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _otpTimer;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  int _otpRemainingSeconds = 0;
  String _verifyingPhone = '';

  @override
  void dispose() {
    _otpTimer?.cancel();
    _phoneController.dispose();
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
    });
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

  Future<void> _sendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    final form = _phoneFormKey.currentState;
    if (form == null || !form.validate()) {
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
    setState(() {
      _verifyingPhone = _phoneController.text.trim();
      _otpRemainingSeconds = resendAfterSeconds;
      _otpSent = true;
    });
    _startOtpTimer();
    _showMessage(body['message']?.toString() ?? 'OTP sent successfully');
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp) {
      return;
    }

    final form = _otpFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isVerifyingOtp = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.PHONE_VERIFICATION_VERIFY,
      data: {'phone': _verifyingPhone, 'otp': _otpCode},
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }
    setState(() => _isVerifyingOtp = false);

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

    _otpTimer?.cancel();
    _showMessage(
      body['message']?.toString() ?? 'Phone number verified successfully',
    );
    Get.offAllNamed(AppRoutes.dashboard);
  }

  void _changeNumber() {
    _otpTimer?.cancel();
    setState(() {
      _otpSent = false;
      _otpRemainingSeconds = 0;
    });
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
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FD),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _otpSent
                  ? _buildOtpStep(theme)
                  : _buildPhoneStep(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(ThemeData theme) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF7C3AED),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verify your mobile number',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF17172B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For your account\'s safety, please verify your mobile number to continue using the app.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _phoneController,
            validator: _validatePhoneNumber,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              LengthLimitingTextInputFormatter(18),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter 10-digit mobile number',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  widthFactor: 1,
                  child: Text('+91', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3E4EE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3E4EE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSendingOtp ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSendingOtp
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    return Form(
      key: _otpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF7C3AED),
            ),
            child: const Icon(
              Icons.sms_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter verification code',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF17172B),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Enter the 6-digit code sent to ',
              children: [
                TextSpan(
                  text: _maskedVerifyingPhone,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                child: SizedBox(
                  width: 46,
                  height: 56,
                  child: TextFormField(
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
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF6F3FD),
                      contentPadding: EdgeInsets.zero,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE3E4EE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE3E4EE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_otpRemainingSeconds > 0)
            Text(
              'Resend code in $_otpTime',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            GestureDetector(
              onTap: _isSendingOtp ? null : _sendOtp,
              child: Text(
                'Resend Code',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifyingOtp ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isVerifyingOtp
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isVerifyingOtp ? null : _changeNumber,
            child: const Text(
              'Change number',
              style: TextStyle(
                color: Color(0xFF6B7080),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
