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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordLoginFormKey = GlobalKey<FormState>();
  final _phoneLoginFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _storage = const FlutterSecureStorage();

  Timer? _otpTimer;
  StateSetter? _otpSheetSetState;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isOtpLoading = false;
  bool _otpSent = false;
  bool _otpConsentAccepted = true;
  int _otpRemainingSeconds = 600;

  @override
  void dispose() {
    _otpTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    final form = _passwordLoginFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.LOGIN,
      data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      },
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
    await _completeLoginFromResponse(
      response: response,
      fallbackEmail: _emailController.text.trim(),
    );
  }

  Future<void> _sendOtp() async {
    if (!_otpConsentAccepted) {
      return;
    }

    final form = _phoneLoginFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isOtpLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.loginWithOtpSend,
      data: {'phone': _phoneController.text.trim()},
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isOtpLoading = false);

    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _otpSent = true;
      _otpRemainingSeconds = 600;
    });
    _startOtpTimer();
    final body = response.data as Map<String, dynamic>;
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
      endpoint: ApiService.loginWithOtpVerify,
      data: {'phone': _phoneController.text.trim(), 'otp': _otpCode},
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isOtpLoading = false);
    _rebuildOtpSheet();
    await _completeLoginFromResponse(
      response: response,
      fallbackPhone: _phoneController.text.trim(),
    );
  }

  Future<void> _completeLoginFromResponse({
    required ApiResponse<dynamic> response,
    String fallbackEmail = '',
    String fallbackPhone = '',
  }) async {
    if (!response.success || response.data is! Map<String, dynamic>) {
      _showMessage(response.message, isError: true);
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = _asStringKeyMap(body['data']);
    final user = _findUserPayload(data);
    final token = data?['token']?.toString() ?? '';
    final userId = _firstNonEmpty(user, const ['_id', 'id', 'userId']);

    if (token.isEmpty) {
      _showMessage(
        body['message']?.toString() ?? 'Login failed',
        isError: true,
      );
      return;
    }

    await _storage.write(key: StorageKeys.authToken, value: token);
    final profileData = await _loadProfileAfterLogin(user);
    final profileSetupCompleted =
        _profileSetupFlag(data) ??
        _profileSetupFlag(user) ??
        _isProfileSetupComplete(profileData);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_id', userId);
    await preferences.setString(
      'user_name',
      _firstNonEmpty(profileData, const ['name']),
    );
    await preferences.setString(
      'user_email',
      _firstNonEmpty(profileData, const ['email'], fallbackEmail),
    );
    await preferences.setString(
      'user_phone',
      _firstNonEmpty(profileData, const [
        'phoneNumber',
        'phone',
      ], fallbackPhone),
    );
    await preferences.setBool(
      StorageKeys.profileSetupCompleted,
      profileSetupCompleted,
    );
    await SessionManager.instance.login(
      token: token,
      userId: userId,
      userData: _firstNonEmpty(profileData, const ['name']),
      email: _firstNonEmpty(profileData, const ['email'], fallbackEmail),
      profilePic: _firstNonEmpty(profileData, const ['profilePic']),
    );

    if (!mounted) {
      return;
    }

    _showMessage(body['message']?.toString() ?? 'Login successful');
    Get.offAllNamed(
      profileSetupCompleted
          ? AppRoutes.dashboard
          : AppRoutes.studentProfileSetup,
    );
  }

  Future<Map<String, dynamic>?> _loadProfileAfterLogin(
    Map<String, dynamic>? loginUser,
  ) async {
    if (_isProfileSetupComplete(loginUser)) {
      return loginUser;
    }

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_PROFILE,
      fromJson: (json) => json,
      showLoader: false,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return loginUser;
    }

    final body = response.data as Map<String, dynamic>;
    return _findUserPayload(_asStringKeyMap(body['data'])) ?? loginUser;
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

  void _backToPasswordLogin() {
    _otpTimer?.cancel();
    if (Get.isBottomSheetOpen ?? false) {
      Get.back<void>();
      return;
    }
    setState(() => _otpSent = false);
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
              child: SingleChildScrollView(child: _buildOtpVerification(theme)),
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

  Map<String, dynamic>? _findUserPayload(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }

    for (final key in const ['user', 'profile', 'student']) {
      final nested = _asStringKeyMap(data[key]);
      if (nested != null) {
        return {...data, ...nested};
      }
    }

    return data;
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

  String _firstNonEmpty(
    Map<String, dynamic>? data,
    List<String> keys, [
    String fallback = '',
  ]) {
    if (data == null) {
      return fallback;
    }

    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (_hasProfileValue(value)) {
        return value;
      }
    }

    return fallback;
  }

  bool _isProfileSetupComplete(Map<String, dynamic>? data) {
    final profile = _findUserPayload(data);
    if (profile == null) {
      return false;
    }

    final profileSetupFlag = _profileSetupFlag(profile);
    if (profileSetupFlag != null) {
      return profileSetupFlag;
    }

    return _hasAnyProfileValue(profile, const [
          'instructionMedium',
          'medium',
        ]) &&
        _hasAnyProfileValue(profile, const [
          'educationalBoard',
          'educationBoard',
          'board',
        ]) &&
        _hasAnyProfileValue(profile, const [
          'classLevel',
          'userClass',
          'class',
          'grade',
        ]);
  }

  bool? _profileSetupFlag(Map<String, dynamic>? data) {
    final profile = _findUserPayload(data);
    if (profile == null) {
      return null;
    }

    for (final key in const [
      'isProfileSetupComplete',
      'isProfileComplete',
      'profileSetupCompleted',
      'profileCompleted',
      'isProfileSetup',
    ]) {
      final value = profile[key];
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

  bool _hasAnyProfileValue(Map<String, dynamic> data, List<String> keys) {
    return keys.any((key) => _hasProfileValue(data[key]?.toString()));
  }

  bool _hasProfileValue(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    return text.isNotEmpty && text != '-' && text != 'null';
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

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please enter your password';
    }
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
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
      backgroundColor: const Color(0xFFF5F6FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          child: _buildLoginForm(theme),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      key: const ValueKey('login'),
      children: [
        const SizedBox(height: 8),
        _AppMark(size: 350),
        const SizedBox(height: 18),
        _AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form(
              //   key: _passwordLoginFormKey,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       _FieldLabel('Email'),
              //       const SizedBox(height: 8),
              //       _AuthTextField(
              //         controller: _emailController,
              //         hintText: 'Enter your email',
              //         keyboardType: TextInputType.emailAddress,
              //         prefixIcon: Icons.mail_outline_rounded,
              //         validator: _validateEmail,
              //       ),
              //       const SizedBox(height: 16),
              //       _FieldLabel('Password'),
              //       const SizedBox(height: 8),
              //       _AuthTextField(
              //         controller: _passwordController,
              //         hintText: 'Enter your Password',
              //         prefixIcon: Icons.lock_outline_rounded,
              //         obscureText: _obscurePassword,
              //         validator: _validatePassword,
              //         suffixIcon: IconButton(
              //           onPressed: () {
              //             setState(() => _obscurePassword = !_obscurePassword);
              //           },
              //           icon: Icon(
              //             _obscurePassword
              //                 ? Icons.visibility_off_outlined
              //                 : Icons.visibility_outlined,
              //             color: const Color(0xFF667085),
              //             size: 20,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 6),
              //       Align(
              //         alignment: Alignment.centerRight,
              //         child: TextButton(
              //           onPressed: _isLoading
              //               ? null
              //               : () => Get.toNamed(AppRoutes.forgotPassword),
              //           style: TextButton.styleFrom(
              //             foregroundColor: const Color(0xFF4F46E5),
              //             padding: EdgeInsets.zero,
              //             minimumSize: const Size(10, 28),
              //             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //           ),
              //           child: const Text(
              //             'Forgot Password?',
              //             style: TextStyle(
              //               fontSize: 12,
              //               fontWeight: FontWeight.w700,
              //             ),
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 12),
              //       _PrimaryButton(
              //         label: 'Login',
              //         isLoading: _isLoading,
              //         onPressed: _isLoading ? null : _login,
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 20),
              // Row(
              //   children: [
              //     const Expanded(child: Divider(color: Color(0xFFD8DCEB))),
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 12),
              //       child: Text(
              //         'OR',
              //         style: theme.textTheme.bodySmall?.copyWith(
              //           color: const Color(0xFF8A90A2),
              //           fontWeight: FontWeight.w700,
              //         ),
              //       ),
              //     ),
              //     const Expanded(child: Divider(color: Color(0xFFD8DCEB))),
              //   ],
              // ),
              // const SizedBox(height: 16),
              Form(
                key: _phoneLoginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Mobile Number'),
                    const SizedBox(height: 8),
                    _PhoneField(
                      controller: _phoneController,
                      validator: _validatePhone,
                    ),
                    // const SizedBox(height: 18),
                    // _OtpConsentCheckbox(
                    //   value: _otpConsentAccepted,
                    //   onChanged: (value) {
                    //     setState(() => _otpConsentAccepted = value ?? false);
                    //   },
                    // ),
                    const SizedBox(height: 26),
                    _PrimaryButton(
                      label: 'Login with OTP',
                      isLoading: _isOtpLoading,
                      onPressed: _isOtpLoading || !_otpConsentAccepted
                          ? null
                          : _sendOtp,
                    ),
                    const SizedBox(height: 28),
                    _PrimaryButton(
                      label: 'Register',
                      isLoading: false,
                      backgroundColor: const Color(0xFFFAF9FF),
                      foregroundColor: const Color(0xFF1F2430),
                      shadowColor: const Color(
                        0xFF4F46E5,
                      ).withValues(alpha: 0.18),
                      onPressed: () => Get.toNamed(AppRoutes.createAccount),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerification(ThemeData theme) {
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
            'We’ve sent a 6-digit code to $_maskedPhone.',
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
            'Didn’t receive the code?',
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
          _PrimaryButton(
            label: 'Verify & Continue',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isOtpLoading,
            onPressed: _isOtpLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isOtpLoading ? null : _backToPasswordLogin,
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
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(22),
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
        borderRadius: BorderRadius.circular(16),
        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.fill),
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
      child: child,
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
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF3D4050),
        fontWeight: FontWeight.w800,
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
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF7A8295), size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE1E5F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE1E5F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
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
      decoration: InputDecoration(
        filled: false,
        hintText: 'Enter your number',
        hintStyle: const TextStyle(
          color: Color(0xFF777989),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          width: 92,
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+91',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF767A8A),
                size: 18,
              ),
              SizedBox(width: 14),
              SizedBox(
                width: 1,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFCAD0DD)),
                ),
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
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
            side: const BorderSide(color: Color(0xFF7A8295), width: 1.4),
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
                color: Color(0xFF3D4050),
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF4F46E5),
    this.foregroundColor = Colors.white,
    this.shadowColor,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? shadowColor;
  final IconData? icon;

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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
