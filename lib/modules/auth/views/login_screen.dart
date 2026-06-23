import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
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
        body['message']?.toString() ?? 'Login failed',
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
    await preferences.setBool(StorageKeys.profileSetupCompleted, true);
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

    _showMessage(body['message']?.toString() ?? 'Login successful');
    Get.offAllNamed(AppRoutes.dashboard);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  child: AspectRatio(
                    aspectRatio: 1.35,
                    child: Image.asset(
                      'assets/images/login_image_back.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  'Welcome Back',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF163B98),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your journey to mastery continues here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF101828).withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AuthTextField(
                        controller: _emailController,
                        hintText: 'alex@school.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF344054),
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Get.toNamed(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0B5EAE),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      // const SizedBox(height: 18),
                      // Row(
                      //   children: [
                      //     const Expanded(
                      //       child: Divider(
                      //         color: Color(0xFFD6DCE8),
                      //         thickness: 1,
                      //       ),
                      //     ),
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 14),
                      //       child: Text(
                      //         'OR',
                      //         style: theme.textTheme.bodySmall?.copyWith(
                      //           color: const Color(0xFF98A2B3),
                      //           fontWeight: FontWeight.w600,
                      //         ),
                      //       ),
                      //     ),
                      //     const Expanded(
                      //       child: Divider(
                      //         color: Color(0xFFD6DCE8),
                      //         thickness: 1,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 18),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 52,
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
                      //       'assets/images/google-icon.png',
                      //       width: 22,
                      //       height: 22,
                      //       fit: BoxFit.contain,
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
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Don’t have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF344054),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.createAccount),
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // const Row(
                //   children: [
                //     Expanded(
                //       child: _InfoCard(
                //         icon: Icons.verified_user_outlined,
                //         title: 'Secure Login',
                //         subtitle: 'Student data protected',
                //       ),
                //     ),
                //     SizedBox(width: 12),
                //     Expanded(
                //       child: _InfoCard(
                //         icon: Icons.bookmark_border_rounded,
                //         title: 'Save Progress',
                //         subtitle: 'Resume where you left',
                //       ),
                //     ),
                //   ],
                // ),
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
          horizontal: 10,
          vertical: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF163B98), size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF475467),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
