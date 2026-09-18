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
    // Guard against a second tap firing login a second time.
    if (_isLoading) {
      return;
    }

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
    if (!_otpConsentAccepted || _isOtpLoading) {
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

    await SecureStorageService.write(StorageKeys.authToken, token);
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

    final hasVerifiedMobile = _firstNonEmpty(profileData, const [
      'phoneNumber',
      'phone',
    ], fallbackPhone).isNotEmpty;

    if (!hasVerifiedMobile) {
      Get.offAllNamed(AppRoutes.phoneVerification);
      return;
    }

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

  void _showComingSoon(String feature) {
    Get.snackbar(
      feature,
      '$feature login is coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _AuthColors.textPrimary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
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
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: _buildLoginForm(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 0),
        const _AppMark(size: 150),
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
        // const SizedBox(height: 26),
        _AuthCard(
          child: Form(
            key: _phoneLoginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: _AuthColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Continue your smart learning journey.',
                  style: TextStyle(
                    color: _AuthColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                const _FieldLabel('MOBILE NUMBER'),
                const SizedBox(height: 8),
                _PhoneField(
                  controller: _phoneController,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 8),
                const Padding(padding: EdgeInsets.only(left: 4)),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: 'Continue with OTP',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isOtpLoading,
                  onPressed: _isOtpLoading || !_otpConsentAccepted
                      ? null
                      : _sendOtp,
                ),
                const SizedBox(height: 22),
                const _OrDivider(label: 'OR CONTINUE WITH'),
                const SizedBox(height: 22),
                _SecondaryButton(
                  label: 'Create new account',
                  onPressed: () => Get.toNamed(AppRoutes.createAccount),
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
              text: 'By continuing, you agree to our \n',
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

  Widget _buildOtpVerification(ThemeData theme) {
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
              color: const Color(0xFFE2E4EE),
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
              color: const Color(0xFF14141F),
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
                    color: Color(0xFF14141F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7080),
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
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 6),
                Text(
                  'Code expires in ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7080),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _otpTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _PrimaryButton(
            label: 'Verify & Continue',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isOtpLoading,
            onPressed: _isOtpLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isOtpLoading ? null : _backToPasswordLogin,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7080),
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
  static const Color whatsappBackground = Color(0xFFECFDF3);
  static const Color whatsappBorder = Color(0xFFBBF0CF);
  static const Color whatsappText = Color(0xFF15803D);
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

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 210,
      padding: const EdgeInsets.all(4),

      child: ClipRRect(
        // borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset('assets/icon/app_icon.png'),
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

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.validator});

  final TextEditingController controller;
  final String? Function(String?) validator;

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

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
        border: _border(_AuthColors.border),
        enabledBorder: _border(_AuthColors.border),
        focusedBorder: _border(_AuthColors.primary, 1.6),
        errorBorder: _border(_AuthColors.error),
        focusedErrorBorder: _border(_AuthColors.error, 1.6),
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

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

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
          border: _border(_AuthColors.border),
          enabledBorder: _border(_AuthColors.border),
          focusedBorder: _border(_AuthColors.primary, 1.8),
          errorBorder: _border(_AuthColors.error),
          focusedErrorBorder: _border(_AuthColors.error, 1.8),
        ),
      ),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ],
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
