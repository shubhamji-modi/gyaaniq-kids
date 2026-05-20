import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  String? _mobileError;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _showOtpBottomSheet(String phoneNumber) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OtpVerificationSheet(phoneNumber: phoneNumber),
    );
  }

  void _continueWithOtp() {
    final phoneNumber = _mobileController.text.trim();
    final validationMessage = _validateMobile(phoneNumber);

    setState(() {
      _mobileError = validationMessage;
    });

    if (validationMessage != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    _showOtpBottomSheet(phoneNumber);
  }

  String? _validateMobile(String value) {
    if (value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Mobile number must be 10 digits';
    }
    if (!RegExp(r'^[6-9]').hasMatch(value)) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Column(
            children: [
              const SizedBox(height: 00),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/login_image_back.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 0),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF163B98),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontSize: 18
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your journey to mastery continues here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE2F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Email',
                    //   style: theme.textTheme.bodySmall?.copyWith(
                    //     color: const Color(0xFF4A5568),
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Container(
                    //   height: 48,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFFDFDFF),
                    //     borderRadius: BorderRadius.circular(8),
                    //     border: Border.all(
                    //       color: _mobileError == null
                    //           ? const Color(0xFFD9E1EE)
                    //           : const Color(0xFFEB5757),
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //
                    //       const SizedBox(width: 10),
                    //       Expanded(
                    //         child: TextField(
                    //           controller: _mobileController,
                    //           keyboardType: TextInputType.phone,
                    //           inputFormatters: [
                    //             FilteringTextInputFormatter.digitsOnly,
                    //             LengthLimitingTextInputFormatter(10),
                    //           ],
                    //           onChanged: (_) {
                    //             if (_mobileError != null) {
                    //               setState(() {
                    //                 _mobileError = null;
                    //               });
                    //             }
                    //           },
                    //           decoration: InputDecoration(
                    //             hintText: 'Enter your email',
                    //             hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    //               color: const Color(0xFF98A2B3),
                    //             ),
                    //             border: InputBorder.none,
                    //             isCollapsed: true,
                    //           ),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 10),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 18),
                    // Text(
                    //   'Password',
                    //   style: theme.textTheme.bodySmall?.copyWith(
                    //     color: const Color(0xFF4A5568),
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Container(
                    //   height: 48,
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFFDFDFF),
                    //     borderRadius: BorderRadius.circular(8),
                    //     border: Border.all(
                    //       color: _mobileError == null
                    //           ? const Color(0xFFD9E1EE)
                    //           : const Color(0xFFEB5757),
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //
                    //       const SizedBox(width: 10),
                    //       Expanded(
                    //         child: TextField(
                    //           controller: _mobileController,
                    //           keyboardType: TextInputType.phone,
                    //           inputFormatters: [
                    //             FilteringTextInputFormatter.digitsOnly,
                    //             LengthLimitingTextInputFormatter(10),
                    //           ],
                    //           onChanged: (_) {
                    //             if (_mobileError != null) {
                    //               setState(() {
                    //                 _mobileError = null;
                    //               });
                    //             }
                    //           },
                    //           decoration: InputDecoration(
                    //             hintText: 'Enter your password',
                    //             hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    //               color: const Color(0xFF98A2B3),
                    //             ),
                    //             border: InputBorder.none,
                    //             isCollapsed: true,
                    //           ),
                    //         ),
                    //       ),
                    //       const SizedBox(width: 10),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 46,
                    //   child: ElevatedButton(
                    //     onPressed: _continueWithOtp,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFF4A4FD9),
                    //       foregroundColor: Colors.white,
                    //       elevation: 8,
                    //       shadowColor: const Color(
                    //         0xFF4A4FD9,
                    //       ).withValues(alpha: 0.28),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(28),
                    //       ),
                    //     ),
                    //     child: const Text(
                    //       'Login',
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w700,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 18),

                    const SizedBox(height: 10),
                    Text(
                      'Mobile Number',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4A5568),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _mobileError == null
                              ? const Color(0xFFD9E1EE)
                              : const Color(0xFFEB5757),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFD9E1EE)),
                              ),
                            ),
                            child: Text(
                              '+91',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: (_) {
                                if (_mobileError != null) {
                                  setState(() {
                                    _mobileError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter your number',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF98A2B3),
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                    if (_mobileError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _mobileError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFEB5757),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _continueWithOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4FD9),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(
                            0xFF4A4FD9,
                          ).withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Continue with OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFD6DCE8),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF98A2B3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFD6DCE8),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF111827),
                          side: const BorderSide(color: Color(0xFFD6DCE8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/images/google-icon.png',
                          width: 25,
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                        label: const Text(
                          'login with Google',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 44,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () {},
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: const Color(0xFF111827),
                    //       side: const BorderSide(color: Color(0xFFD6DCE8)),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(24),
                    //       ),
                    //     ),
                    //     icon: Image.asset(
                    //       'assets/images/apple_logo.png',
                    //       width: 20,
                    //       height: 20,
                    //       fit: BoxFit.contain,
                    //     ),
                    //     label: const Text(
                    //       'login with Apple',
                    //       style: TextStyle(
                    //         fontSize: 13,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Secure Login',
                      subtitle: 'Student data protected',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Save Progress',
                      subtitle: 'Resume where \nyou left',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpVerificationSheet extends StatefulWidget {
  const _OtpVerificationSheet({required this.phoneNumber});

  final String phoneNumber;

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  static const int _initialSeconds = 30;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _remainingSeconds = _initialSeconds;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < _controllers.length; index++) {
      _controllers[index].addListener(_refresh);
      _focusNodes[index].addListener(_refresh);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
    _startTimer();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds == 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.removeListener(_refresh);
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.removeListener(_refresh);
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _maskedPhoneNumber {
    final lastFour = widget.phoneNumber.substring(
      widget.phoneNumber.length - 4,
    );
    return '+91 ••••••$lastFour';
  }

  String get _timerLabel {
    final seconds = _remainingSeconds.toString().padLeft(2, '0');
    return '0:$seconds';
  }

  bool get _isOtpComplete =>
      _controllers.every((controller) => controller.text.trim().isNotEmpty);

  Future<void> _verifyAndContinue() async {
    await _storage.write(
      key: StorageKeys.authToken,
      value: 'demo-token-${widget.phoneNumber}',
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    Get.offAllNamed(AppRoutes.studentProfileSetup);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canResend = _remainingSeconds == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DEEA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verify Phone',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We've sent a 4-digit code to $_maskedPhoneNumber.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please enter it below to continue.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasValue = _controllers[index].text.isNotEmpty;
                final hasFocus = _focusNodes[index].hasFocus;
                final isActive = hasFocus || hasValue;

                return Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 14),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (value) => _onOtpChanged(value, index),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: hasValue
                            ? const Color(0xFF4A4FD9)
                            : const Color(0xFFD0D5DD),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        hintText: hasValue ? null : '•',
                        hintStyle: const TextStyle(
                          color: Color(0xFFD0D5DD),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isActive
                                ? const Color(0xFF5A5FF2)
                                : const Color(0xFFD9DEEA),
                            width: isActive ? 1.6 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF5A5FF2),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Text(
              "Didn't receive the code?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: canResend
                      ? () {
                          for (final controller in _controllers) {
                            controller.clear();
                          }
                          _focusNodes.first.requestFocus();
                          _startTimer();
                          setState(() {});
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: canResend
                        ? const Color(0xFF4A4FD9)
                        : const Color(0xFF98A2B3),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Resend Code'),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canResend
                        ? const Color(0xFFE9EEF9)
                        : const Color(0xFFE9DDFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _timerLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: canResend
                          ? const Color(0xFF64748B)
                          : const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isOtpComplete ? _verifyAndContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4FD9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD9DDF3),
                  disabledForegroundColor: const Color(0xFF8D96B8),
                  elevation: 10,
                  shadowColor: const Color(0xFF4A4FD9).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF163B98)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 10,
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
