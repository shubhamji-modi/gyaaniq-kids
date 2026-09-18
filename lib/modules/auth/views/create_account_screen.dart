import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/service/api_service.dart';
import '../../../core/service/session_manager.dart';
import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';
import '../../../core/service/secure_storage_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _otpTimer;
  StateSetter? _otpSheetSetState;
  bool _isLoading = false;
  bool _isOtpLoading = false;
  bool _otpSent = false;
  bool _otpConsentAccepted = true;
  bool _registrationWentToBackground = false;
  int _otpRemainingSeconds = 600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((_isLoading || _isOtpLoading) && state != AppLifecycleState.resumed) {
      _registrationWentToBackground = true;
    }
  }

  Future<void> _showReviewSheet() async {
    if (!_otpConsentAccepted || _isLoading || _otpSent) {
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignupReviewSheet(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );

    if (confirmed == true && mounted) {
      await _register();
    }
  }

  Future<void> _register() async {
    // Guard against a second tap firing register a second time.
    if (!_otpConsentAccepted || _isLoading) {
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    _registrationWentToBackground = false;
    setState(() => _isLoading = true);

    final requestData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      requestData['email'] = email;
    }

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.REGISTER,
      data: requestData,
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;

    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _otpSent = true;
      _otpRemainingSeconds = 600;
    });
    _startOtpTimer();
    _showMessage(body['message']?.toString() ?? 'OTP sent successfully');
    await _showOtpBottomSheet();
  }

  Future<void> _verifyOtp() async {
    if (_isOtpLoading) {
      return;
    }

    final form = _otpFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isOtpLoading = true);
    _rebuildOtpSheet();

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.registerVerifyOtp,
      data: {'phone': _phoneController.text.trim(), 'otp': _otpCode},
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isOtpLoading = false);
    _rebuildOtpSheet();
    await _completeRegistrationFromResponse(response);
  }

  Future<void> _completeRegistrationFromResponse(
    ApiResponse<dynamic> response,
  ) async {
    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final responseData = _asStringKeyMap(body['data']);
    final token = responseData?['token']?.toString() ?? '';
    final userId =
        responseData?['_id']?.toString() ??
        responseData?['id']?.toString() ??
        responseData?['userId']?.toString() ??
        '';
    if (token.isEmpty) {
      _showMessage(
        body['message']?.toString() ?? 'Registration failed',
        isError: true,
      );
      return;
    }

    final profileSetupCompleted = _profileSetupFlag(responseData) ?? false;

    if (_registrationWentToBackground) {
      _showMessage('Registration completed. Please login again to continue.');
      return;
    }

    await SecureStorageService.write(StorageKeys.authToken, token);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_id', userId);
    await preferences.setString(
      'user_name',
      responseData?['name']?.toString() ?? '',
    );
    await preferences.setString(
      'user_email',
      responseData?['email']?.toString() ?? _emailController.text.trim(),
    );
    await preferences.setString(
      'user_phone',
      responseData?['phoneNumber']?.toString() ?? _phoneController.text.trim(),
    );
    await preferences.setBool(
      StorageKeys.profileSetupCompleted,
      profileSetupCompleted,
    );
    await SessionManager.instance.login(
      token: token,
      userId: userId,
      userData: responseData?['name']?.toString() ?? '',
      email: responseData?['email']?.toString() ?? _emailController.text.trim(),
      profilePic: responseData?['profilePic']?.toString(),
    );

    if (!mounted) {
      return;
    }

    _showMessage(body['message']?.toString() ?? 'Account created successfully');
    Get.offAllNamed(
      profileSetupCompleted
          ? AppRoutes.dashboard
          : AppRoutes.studentProfileSetup,
    );
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

  void _closeOtpSheet(BuildContext sheetContext) {
    _otpTimer?.cancel();
    if (mounted) {
      setState(() => _otpSent = false);
    }
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
      return;
    }
  }

  void _rebuildOtpSheet() {
    _otpSheetSetState?.call(() {});
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                child: _buildOtpVerification(theme, context),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _otpSheetSetState = null;
      _otpTimer?.cancel();
      if (mounted && _otpSent) {
        setState(() => _otpSent = false);
      }
    });
  }

  String get _otpCode => _otpControllers.map((field) => field.text).join();

  String get _otpTime {
    final minutes = (_otpRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    if (local.length < 4) {
      return '+91 $local';
    }
    return '+91 •••• ${local.substring(local.length - 4)}';
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

  bool? _profileSetupFlag(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    for (final key in const [
      'isProfileSetupComplete',
      'isProfileComplete',
      'profileSetupCompleted',
      'profileCompleted',
      'isProfileSetup',
    ]) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'completed') {
        return true;
      }
      if (text == 'false' || text == '0' || text == 'incomplete') {
        return false;
      }
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
      margin: const EdgeInsets.all(16),
    );
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return null;
    }
    if (!GetUtils.isEmail(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
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

  String? _validateOtp(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return '';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _AuthColors.backgroundBottom,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Container(
          decoration: const BoxDecoration(gradient: _backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 1, 10, 28),
              child: _buildSignupForm(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        const _AppMark(size: 84),
        const SizedBox(height: 16),
        // const _Wordmark(),
        // const SizedBox(height: 4),
        // const Text(
        //   'Learn smart. Score more.',
        //   textAlign: TextAlign.center,
        //   style: TextStyle(
        //     color: _AuthColors.textSecondary,
        //     fontSize: 14,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        const SizedBox(height: 5),
        _AuthCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please Enter Your Details to Continue',
                  style: TextStyle(
                    color: _AuthColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                // const SizedBox(height: 3),
                // const Text(
                //   'Fill in your details and we will send a 6-digit OTP to verify your number.',
                //   style: TextStyle(
                //     color: _AuthColors.textSecondary,
                //     fontSize: 14,
                //     fontWeight: FontWeight.w400,
                //     height: 1.45,
                //   ),
                // ),
                const SizedBox(height: 15),
                const _FieldLabel('FULL NAME'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _nameController,
                  hintText: 'Alex Johnson',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 18),
                const _FieldLabel('EMAIL ADDRESS (OPTIONAL)'),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _emailController,
                  hintText: 'alex@school.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                const _FieldLabel('MOBILE NUMBER'),
                const SizedBox(height: 8),
                _PhoneField(
                  controller: _phoneController,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                _OtpConsentCheckbox(
                  value: _otpConsentAccepted,
                  onChanged: (value) {
                    setState(() => _otpConsentAccepted = value ?? false);
                  },
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: 'Send OTP',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading || !_otpConsentAccepted
                      ? null
                      : _showReviewSheet,
                ),
                const SizedBox(height: 22),
                const _OrDivider(label: 'ALREADY HAVE AN ACCOUNT?'),
                const SizedBox(height: 18),
                _SecondaryButton(
                  label: 'Login',
                  onPressed: _isLoading ? null : () => Get.back(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text.rich(
            const TextSpan(
              text: 'By continuing, you agree to our ',
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: _AuthColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' & '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: _AuthColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AuthColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerification(ThemeData theme, BuildContext sheetContext) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('otp'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _AuthColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _brandGradient,
            ),
            child: const Icon(
              Icons.sms_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Verify your number',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: _AuthColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Enter the 6-digit code sent to ',
              children: [
                TextSpan(
                  text: _maskedPhone,
                  style: const TextStyle(
                    color: _AuthColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _AuthColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                child: _OtpBox(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  validator: _validateOtp,
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
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _AuthColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Code expires in ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _AuthColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _otpTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _AuthColors.primary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _PrimaryButton(
            label: 'Verify & Create Account',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isOtpLoading,
            onPressed: _isOtpLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isOtpLoading
                ? null
                : () => _closeOtpSheet(sheetContext),
            style: TextButton.styleFrom(
              foregroundColor: _AuthColors.textSecondary,
            ),
            child: const Text(
              'Change number',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthColors {
  _AuthColors._();

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color primaryBorder = Color(0xFFC9B8F7);
  static const Color backgroundTop = Color(0xFFECE6FA);
  static const Color backgroundMiddle = Color(0xFFF6F3FD);
  static const Color backgroundBottom = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0xFF7C3AED);
  static const Color border = Color(0xFFE3E4EE);
  static const Color fieldBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF17172B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA1B2);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFE11D48);
  static const Color gradientStart = Color(0xFF6F2BEF);
  static const Color gradientMiddle = Color(0xFFB13BB8);
  static const Color gradientEnd = Color(0xFFFF6B4A);
}

const LinearGradient _brandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    _AuthColors.gradientStart,
    _AuthColors.gradientMiddle,
    _AuthColors.gradientEnd,
  ],
  stops: [0.0, 0.55, 1.0],
);

const LinearGradient _backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    _AuthColors.backgroundTop,
    _AuthColors.backgroundMiddle,
    _AuthColors.backgroundBottom,
  ],
  stops: [0.0, 0.45, 1.0],
);

OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 210,
      padding: const EdgeInsets.all(4),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(size * 0.26),
      //   boxShadow: [
      //     BoxShadow(
      //       color: _AuthColors.cardShadow.withValues(alpha: 0.18),
      //       blurRadius: 24,
      //       offset: const Offset(0, 10),
      //     ),
      //   ],
      // ),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.fill),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Gyaan',
        style: TextStyle(color: _AuthColors.textPrimary),
        children: [
          TextSpan(
            text: 'IQ',
            style: TextStyle(color: _AuthColors.primary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: _AuthColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _AuthColors.cardShadow.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _AuthColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: _AuthColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _AuthColors.border, height: 1)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AuthColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: _AuthColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _AuthColors.fieldBackground,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _AuthColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, color: _AuthColors.textMuted, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(_AuthColors.border),
        enabledBorder: _inputBorder(_AuthColors.border),
        focusedBorder: _inputBorder(_AuthColors.primary, 1.6),
        errorBorder: _inputBorder(_AuthColors.error),
        focusedErrorBorder: _inputBorder(_AuthColors.error, 1.6),
        errorStyle: const TextStyle(
          color: _AuthColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
        LengthLimitingTextInputFormatter(18),
      ],
      style: const TextStyle(
        color: _AuthColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _AuthColors.fieldBackground,
        hintText: 'Enter 10-digit number',
        hintStyle: const TextStyle(
          color: _AuthColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        prefixIcon: Container(
          width: 76,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+91',
                style: TextStyle(
                  color: _AuthColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 1,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: _AuthColors.border),
                ),
              ),
            ],
          ),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final isValid = validator(value.text) == null;
            return Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: isValid ? _AuthColors.success : _AuthColors.border,
            );
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(_AuthColors.border),
        enabledBorder: _inputBorder(_AuthColors.border),
        focusedBorder: _inputBorder(_AuthColors.primary, 1.6),
        errorBorder: _inputBorder(_AuthColors.error),
        focusedErrorBorder: _inputBorder(_AuthColors.error, 1.6),
        errorStyle: const TextStyle(
          color: _AuthColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
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
      width: 46,
      height: 56,
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
          color: _AuthColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _AuthColors.backgroundMiddle,
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          border: _inputBorder(_AuthColors.border),
          enabledBorder: _inputBorder(_AuthColors.border),
          focusedBorder: _inputBorder(_AuthColors.primary, 1.8),
          errorBorder: _inputBorder(_AuthColors.error),
          focusedErrorBorder: _inputBorder(_AuthColors.error, 1.8),
        ),
      ),
    );
  }
}

class _OtpConsentCheckbox extends StatelessWidget {
  const _OtpConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _AuthColors.primary,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: _AuthColors.textMuted, width: 1.4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: const Text.rich(
              TextSpan(
                text: 'I accept the ',
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: _AuthColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
              style: TextStyle(
                color: _AuthColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.6,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _brandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _AuthColors.primary.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AuthColors.primaryDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: _AuthColors.primaryBorder, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Preview sheet shown before account creation so the user can confirm or
/// go back and edit their details. Pops `true` to confirm, `false` to edit.
class _SignupReviewSheet extends StatelessWidget {
  const _SignupReviewSheet({
    required this.name,
    required this.email,
    required this.phone,
  });

  final String name;
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _AuthColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Your Details',
                        style: TextStyle(
                          color: _AuthColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Confirm everything looks right before we send your OTP.',
                        style: TextStyle(
                          color: _AuthColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReviewRow(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              value: name,
            ),
            const SizedBox(height: 12),
            _ReviewRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email (Optional)',
              value: email.isEmpty ? 'Not provided' : email,
            ),
            const SizedBox(height: 12),
            _ReviewRow(
              icon: Icons.phone_android_rounded,
              label: 'Mobile Number',
              value: phone,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _AuthColors.primaryDark,
                        side: const BorderSide(
                          color: _AuthColors.primaryBorder,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _PrimaryButton(
                    label: 'Send OTP',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: false,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _AuthColors.backgroundMiddle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AuthColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AuthColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _AuthColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AuthColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
