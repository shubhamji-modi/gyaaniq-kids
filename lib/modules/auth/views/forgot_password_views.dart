import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/service/api_service.dart';
import '../../../routes/app_routes.dart';

class ForgotPasswordViews extends StatefulWidget {
  const ForgotPasswordViews({super.key});

  @override
  State<ForgotPasswordViews> createState() => _ForgotPasswordViewsState();
}

class _ForgotPasswordViewsState extends State<ForgotPasswordViews> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _step = 0;
  int _resendSeconds = 25;
  int? _attemptsRemaining;
  bool _isLoading = false;
  bool _codeVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _timer;

  static const _primaryBlue = Color(0xFF075EAE);
  static const _screenBg = Color(0xFFF7F9FC);
  static const _fieldBg = Color(0xFFE9EDF2);
  static const _textDark = Color(0xFF20242B);
  static const _textMuted = Color(0xFF515B6A);

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _requestCode() async {
    final form = _emailFormKey.currentState;
    if (form != null && !form.validate()) {
      return;
    }
    if (form == null && !GetUtils.isEmail(_email)) {
      _showMessage('Please enter a valid email', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.FORGOT_PASSWORD,
      data: {'email': _email},
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!response.success) {
      _showMessage(response.message, isError: true);
      return;
    }

    _showMessage(_messageFrom(response) ?? 'Reset code sent successfully');
    _startResendTimer();
    setState(() {
      _step = 1;
      _attemptsRemaining = null;
      _codeVerified = false;
    });
    _otpFocusNodes.first.requestFocus();
  }

  Future<void> _verifyCode() async {
    final code = _code;
    if (code.length != 6) {
      _showMessage('Please enter the 6-digit code', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.VERIFY_RESET_CODE,
      data: {'email': _email, 'code': code},
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!response.success) {
      setState(() => _attemptsRemaining = _remainingAttempts(response.data));
      _showMessage(response.message, isError: true);
      return;
    }

    _showMessage(_messageFrom(response) ?? 'Code verified successfully');
    setState(() {
      _step = 2;
      _codeVerified = true;
      _attemptsRemaining = null;
    });
  }

  Future<void> _resetPassword() async {
    final form = _resetFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.RESET_PASSWORD,
      data: {
        'email': _email,
        'code': _code,
        'newPassword': _newPasswordController.text,
      },
      includeAuth: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (!response.success) {
      setState(() => _attemptsRemaining = _remainingAttempts(response.data));
      _showMessage(response.message, isError: true);
      return;
    }

    _showMessage(
      _messageFrom(response) ??
          'Password reset successfully. Please sign in with your new password.',
    );
    Get.offAllNamed(AppRoutes.login);
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 25);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _clearCode() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _codeVerified = false;
      _attemptsRemaining = null;
    });
    _otpFocusNodes.first.requestFocus();
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

  String get _email => _emailController.text.trim().toLowerCase();

  String get _code => _otpControllers.map((field) => field.text).join();

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
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter a new password';
    }
    if (password.length < 6) {
      return 'Minimum 6 characters required';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  int? _remainingAttempts(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final value = error['attemptsRemaining'];
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '');
    }

    final value = data['attemptsRemaining'];
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  String? _messageFrom(ApiResponse<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Get.back()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepIndicator(currentStep: _step),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: switch (_step) {
                        0 => _EmailStep(
                          key: const ValueKey('email-step'),
                          formKey: _emailFormKey,
                          emailController: _emailController,
                          isLoading: _isLoading,
                          onSubmit: _requestCode,
                          validateEmail: _validateEmail,
                        ),
                        1 => _VerifyStep(
                          key: const ValueKey('verify-step'),
                          controllers: _otpControllers,
                          focusNodes: _otpFocusNodes,
                          isLoading: _isLoading,
                          attemptsRemaining: _attemptsRemaining,
                          resendSeconds: _resendSeconds,
                          codeVerified: _codeVerified,
                          onSubmit: _verifyCode,
                          onResend: _resendSeconds == 0 && !_isLoading
                              ? () {
                                  _clearCode();
                                  _requestCode();
                                }
                              : null,
                        ),
                        _ => _ResetStep(
                          key: const ValueKey('reset-step'),
                          formKey: _resetFormKey,
                          newPasswordController: _newPasswordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscureNewPassword: _obscureNewPassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          isLoading: _isLoading,
                          onSubmit: _resetPassword,
                          validatePassword: _validatePassword,
                          validateConfirmPassword: _validateConfirmPassword,
                          onToggleNewPassword: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword,
                          ),
                          onToggleConfirmPassword: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      },
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            top: 4,
            bottom: 4,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back,
                  color: _ForgotPasswordViewsState._primaryBlue,
                  size: 22,
                ),
              ),
            ),
          ),
          const Text(
            'Forgot Password',
            style: TextStyle(
              color: _ForgotPasswordViewsState._primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['EMAIL', 'VERIFY', 'RESET'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const circleSize = 34.0;
        const labelWidth = 92.0;
        const lineHeight = 3.0;
        const circleTop = 0.0;
        const labelTop = 46.0;
        final width = constraints.maxWidth;
        final circleCenterY = circleTop + circleSize / 2;
        final lineLeft = circleSize / 2;
        final lineWidth = width - circleSize;
        final progressWidth = lineWidth * (currentStep.clamp(0, 2) / 2);

        return SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: lineLeft,
                right: lineLeft,
                top: circleCenterY - lineHeight / 2,
                child: Container(
                  height: lineHeight,
                  color: const Color(0xFFD8DEE7),
                ),
              ),
              Positioned(
                left: lineLeft,
                top: circleCenterY - lineHeight / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: progressWidth,
                  height: lineHeight,
                  color: _ForgotPasswordViewsState._primaryBlue,
                ),
              ),
              for (var index = 0; index < 3; index++)
                _StepDot(
                  index: index,
                  currentStep: currentStep,
                  left: switch (index) {
                    0 => 0,
                    1 => width / 2 - circleSize / 2,
                    _ => width - circleSize,
                  },
                  top: circleTop,
                  size: circleSize,
                ),
              for (var index = 0; index < 3; index++)
                Positioned(
                  left: switch (index) {
                    0 => 0,
                    1 => width / 2 - labelWidth / 2,
                    _ => width - labelWidth,
                  },
                  top: labelTop,
                  width: labelWidth,
                  child: Text(
                    _labels[index],
                    textAlign: index == 0
                        ? TextAlign.left
                        : index == 1
                        ? TextAlign.center
                        : TextAlign.right,
                    style: TextStyle(
                      color: index <= currentStep
                          ? _ForgotPasswordViewsState._primaryBlue
                          : const Color(0xFF343A43),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.currentStep,
    required this.left,
    required this.top,
    required this.size,
  });

  final int index;
  final int currentStep;
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    final done = index < currentStep;
    final active = index == currentStep;

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: CircleAvatar(
        backgroundColor: done || active
            ? _ForgotPasswordViewsState._primaryBlue
            : const Color(0xFFE7EBF0),
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF8A93A3),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
    required this.validateEmail,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String? Function(String?) validateEmail;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/Margin.png',
              width: 230,
              height: 230,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Request Reset Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ForgotPasswordViewsState._primaryBlue,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Enter the email address associated with your account. We'll send a 6-digit verification code to reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ForgotPasswordViewsState._textMuted,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _FieldLabel('Email Address'),
          const SizedBox(height: 8),
          _RoundedTextField(
            controller: emailController,
            hintText: 'e.g. mentor@architect.com',
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const SizedBox(height: 26),
          _PrimaryButton(
            text: 'Send Reset Code',
            icon: Icons.arrow_forward,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.isLoading,
    required this.attemptsRemaining,
    required this.resendSeconds,
    required this.codeVerified,
    required this.onSubmit,
    required this.onResend,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isLoading;
  final int? attemptsRemaining;
  final int resendSeconds;
  final bool codeVerified;
  final VoidCallback onSubmit;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RoundIcon(icon: Icons.lock),
        const SizedBox(height: 30),
        const Text(
          'Verify Reset Code',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ForgotPasswordViewsState._textDark,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Please enter the 6-digit code sent to your inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ForgotPasswordViewsState._textMuted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == 5 ? 0 : 7),
              child: _OtpBox(
                controller: controllers[index],
                focusNode: focusNodes[index],
                previousFocusNode: index == 0 ? null : focusNodes[index - 1],
                nextFocusNode: index == 5 ? null : focusNodes[index + 1],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (codeVerified)
          const Text(
            'Code verified successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F9D58),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Text(
            attemptsRemaining == null
                ? '5 attempts remaining'
                : '$attemptsRemaining attempts remaining',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC2410C),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 28),
        Center(
          child: TextButton(
            onPressed: onResend,
            style: TextButton.styleFrom(
              foregroundColor: _ForgotPasswordViewsState._primaryBlue,
              disabledForegroundColor: const Color(0xFF4D5868),
            ),
            child: Text(
              resendSeconds > 0
                  ? "Didn't receive code? Resend in ${resendSeconds}s"
                  : "Didn't receive code? Resend now",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _PrimaryButton(
          text: 'Verify Code',
          icon: Icons.verified_user_outlined,
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _ResetStep extends StatelessWidget {
  const _ResetStep({
    super.key,
    required this.formKey,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onSubmit,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RoundIcon(icon: Icons.restore),
          const SizedBox(height: 30),
          const Text(
            'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ForgotPasswordViewsState._textDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please choose a secure new password for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ForgotPasswordViewsState._textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 34),
          const _FieldLabel('New Password'),
          const SizedBox(height: 8),
          _RoundedTextField(
            controller: newPasswordController,
            hintText: '........',
            obscureText: obscureNewPassword,
            validator: validatePassword,
            suffixIcon: IconButton(
              onPressed: onToggleNewPassword,
              icon: Icon(
                obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFF424B57),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Confirm New Password'),
          const SizedBox(height: 8),
          _RoundedTextField(
            controller: confirmPasswordController,
            hintText: '........',
            obscureText: obscureConfirmPassword,
            validator: validateConfirmPassword,
            suffixIcon: IconButton(
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFF424B57),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _PasswordNote(),
          const SizedBox(height: 30),
          _PrimaryButton(
            text: 'Reset Password',
            icon: Icons.arrow_forward,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.previousFocusNode,
    required this.nextFocusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _ForgotPasswordViewsState._fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: _ForgotPasswordViewsState._primaryBlue,
              width: 1.4,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            nextFocusNode?.requestFocus();
          } else {
            previousFocusNode?.requestFocus();
          }
        },
      ),
    );
  }
}

class _RoundedTextField extends StatelessWidget {
  const _RoundedTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: _ForgotPasswordViewsState._fieldBg,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFA8B0BC), fontSize: 13),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: _ForgotPasswordViewsState._primaryBlue,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ForgotPasswordViewsState._primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _ForgotPasswordViewsState._primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 7,
          shadowColor: _ForgotPasswordViewsState._primaryBlue.withValues(
            alpha: 0.28,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(icon, size: 17),
                ],
              ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 33,
        backgroundColor: const Color(0xFFD6E3FF),
        child: Icon(
          icon,
          color: _ForgotPasswordViewsState._primaryBlue,
          size: 25,
        ),
      ),
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
        color: _ForgotPasswordViewsState._textDark,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PasswordNote extends StatelessWidget {
  const _PasswordNote();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF1F4F8))),
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFEA580C)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum 6 characters required',
                        style: TextStyle(
                          color: _ForgotPasswordViewsState._textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'This will log you out of all other devices to ensure your account remains protected.',
                        style: TextStyle(
                          color: _ForgotPasswordViewsState._textMuted,
                          fontSize: 10,
                          height: 1.45,
                        ),
                      ),
                    ],
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
