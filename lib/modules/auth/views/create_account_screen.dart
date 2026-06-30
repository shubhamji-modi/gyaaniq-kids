import 'package:flutter/material.dart';
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

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showReviewSheet() async {
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
        passwordLength: _passwordController.text.length,
      ),
    );

    if (confirmed == true && mounted) {
      await _register();
    }
  }

  Future<void> _register() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.REGISTER,
      data: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      },
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
    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['token']?.toString() ?? '';
    final userId = data?['_id']?.toString() ?? '';

    if (token.isEmpty) {
      _showMessage(
        body['message']?.toString() ?? 'Registration failed',
        isError: true,
      );
      return;
    }

    await _storage.write(key: StorageKeys.authToken, value: token);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_id', userId);
    await preferences.setString('user_name', data?['name']?.toString() ?? '');
    await preferences.setString(
      'user_email',
      data?['email']?.toString() ?? _emailController.text.trim(),
    );
    await SessionManager.instance.login(
      token: token,
      userId: userId,
      userData: data?['name']?.toString() ?? '',
      email: data?['email']?.toString() ?? _emailController.text.trim(),
      profilePic: data?['profilePic']?.toString(),
    );

    if (!mounted) {
      return;
    }

    _showMessage(body['message']?.toString() ?? 'Account created successfully');
    Get.offAllNamed(AppRoutes.studentProfileSetup);
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

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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
                const SizedBox(height: 8),
                Text(
                  'Join the Journey',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF1D2939),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Unlock your potential with AI-guided learning tailored for you.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFD9DFF1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF101828).withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
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
                        'Email Address',
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
                        'Password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _passwordController,
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF667085),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Confirm Password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF667085),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _showReviewSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF344054),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Login',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085), size: 20),
        suffixIcon: suffixIcon,
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

/// Preview sheet shown before account creation so the user can confirm or
/// go back and edit their details. Pops `true` to confirm, `false` to edit.
class _SignupReviewSheet extends StatelessWidget {
  const _SignupReviewSheet({
    required this.name,
    required this.email,
    required this.passwordLength,
  });

  final String name;
  final String email;
  final int passwordLength;

  @override
  Widget build(BuildContext context) {
    final maskedPassword = '•' * (passwordLength.clamp(6, 12));

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
                        'Confirm everything looks right before we create your account.',
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
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: 12),
            _ReviewRow(
              icon: Icons.lock_outline_rounded,
              label: 'Password',
              value: maskedPassword,
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
                      child: const Text('Confirm & Create'),
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
