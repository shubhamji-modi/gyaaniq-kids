import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/service/api_service.dart';
import '../../../core/service/session_manager.dart';
import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';

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
  final _storage = const FlutterSecureStorage();

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
    if (!_otpConsentAccepted) {
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
    if (!_otpConsentAccepted) {
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
    if (ApiService.useTemporaryAuth) {
      final otpResponse = await ApiService.instance.post<dynamic>(
        endpoint: ApiService.loginWithOtpSend,
        data: {'phone': _phoneController.text.trim()},
        includeAuth: false,
        fromJson: (json) => json,
      );

      if (!mounted) {
        return;
      }

      if (!otpResponse.success || otpResponse.data is! Map<String, dynamic>) {
        _showMessage(otpResponse.message, isError: true);
        return;
      }
    }

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

    await _storage.write(key: StorageKeys.authToken, value: token);
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
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 4),
                const _AppMark(size: 160),
                // const SizedBox(height: 18),
                // Text(
                //   'Join the Journey',
                //   textAlign: TextAlign.center,
                //   style: theme.textTheme.headlineMedium?.copyWith(
                //     color: const Color(0xFF1D2939),
                //     fontWeight: FontWeight.w800,
                //     letterSpacing: -0.6,
                //     fontSize: 25,
                //   ),
                // ),
                // const SizedBox(height: 10),
                // Text(
                //   'Unlock your potential with AI-guided learning tailored for you.',
                //   textAlign: TextAlign.center,
                //   style: theme.textTheme.bodyLarge?.copyWith(
                //     color: const Color(0xFF667085),
                //     height: 1.45,
                //     fontSize: 14,
                //   ),
                // ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 34),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [Color(0xFFE7F8FA), Color(0xFFF3F1FF)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _nameController,
                        hintText: 'Alex Johnson',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Email Address (Optional)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _emailController,
                        hintText: 'alex@school.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Phone Number',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        prefixIcon: Icons.phone_android_rounded,
                        validator: _validatePhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s()]'),
                          ),
                          LengthLimitingTextInputFormatter(18),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _OtpConsentCheckbox(
                        value: _otpConsentAccepted,
                        onChanged: (value) {
                          setState(() => _otpConsentAccepted = value ?? false);
                        },
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: _SignupButton(
                          label: 'Send OTP',
                          isLoading: _isLoading,
                          onPressed: _isLoading || !_otpConsentAccepted
                              ? null
                              : _showReviewSheet,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: _SignupButton(
                          label: 'Login',
                          isLoading: false,
                          backgroundColor: const Color(0xFFFAF9FF),
                          foregroundColor: const Color(0xFF1F2430),
                          shadowColor: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.18),
                          onPressed: _isLoading ? null : () => Get.back(),
                        ),
                      ),
                      // const SizedBox(height: 22),
                      // Row(
                      //   children: [
                      //     const Expanded(
                      //       child: Divider(
                      //         color: Color(0xFFD0D5DD),
                      //         thickness: 1,
                      //       ),
                      //     ),
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 12),
                      //       child: Text(
                      //         'or',
                      //         style: theme.textTheme.bodyMedium?.copyWith(
                      //           color: const Color(0xFF667085),
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //     const Expanded(
                      //       child: Divider(
                      //         color: Color(0xFFD0D5DD),
                      //         thickness: 1,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 22),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 52,
                      //   child: OutlinedButton.icon(
                      //     onPressed: () {},
                      //     style: OutlinedButton.styleFrom(
                      //       foregroundColor: const Color(0xFF111827),
                      //       side: const BorderSide(color: Color(0xFFD0D5DD)),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(26),
                      //       ),
                      //     ),
                      //     icon: Image.asset(
                      //       'assets/images/google-icon.png',
                      //       width: 22,
                      //       height: 22,
                      //     ),
                      //     label: const Text(
                      //       'Continue with Google',
                      //       style: TextStyle(
                      //         fontSize: 14,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            'We have sent a 6-digit code to $_maskedPhone.',
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
            ],
          ),
          const SizedBox(height: 34),
          _SignupButton(
            label: 'Verify & Create Account',
            isLoading: _isOtpLoading,
            onPressed: _isOtpLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isOtpLoading
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
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(9),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(20),
      //   border: Border.all(color: const Color(0xFFE3E6F3)),
      //   boxShadow: [
      //     BoxShadow(
      //       color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
      //       blurRadius: 22,
      //       offset: const Offset(0, 10),
      //     ),
      //   ],
      // ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
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
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085), size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
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

class _OtpConsentCheckbox extends StatelessWidget {
  const _OtpConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4F46E5),
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: Color(0xFF667085), width: 1.4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!value),
            child: const Text(
              'I accept the Privacy Policy.',
              style: TextStyle(
                color: Color(0xFF344054),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupButton extends StatelessWidget {
  const _SignupButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF4F46E5),
    this.foregroundColor = Colors.white,
    this.shadowColor,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          boxShadow: [
            BoxShadow(
              color:
                  shadowColor ??
                  const Color(0xFF4F46E5).withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.65),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(33),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E4EA),
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
                    color: const Color(0xFFEDEBFF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF4F46E5),
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
                          color: Color(0xFF101828),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Confirm everything looks right before we send your OTP.',
                        style: TextStyle(
                          color: Color(0xFF667085),
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
              label: 'Phone Number',
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
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
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
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Send OTP'),
                    ),
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
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A8F9C),
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
                    color: Color(0xFF1B1F2A),
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
