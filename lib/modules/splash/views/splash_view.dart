import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));

    final preferences = await SharedPreferences.getInstance();
    final onboardFlag =
        preferences.getBool(StorageKeys.onboardingCompleted) ?? false;
    final profileSetupDone =
        preferences.getBool(StorageKeys.profileSetupCompleted) ?? false;

    if (!onboardFlag) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    final token = await _storage.read(key: StorageKeys.authToken);

    if (token != null && token.isNotEmpty) {
      if (profileSetupDone) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.studentProfileSetup);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A60D8), Color(0xFF534DF4), Color(0xFFAF75EC)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final width = constraints.maxWidth;
              final horizontalPadding = width * 0.08;
              final brandSize = width * 0.26;
              final brandRadius = brandSize * 0.30;
              final titleSize = width * 0.10;
              final subtitleSize = width * 0.048;
              final footerSize = width * 0.035;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: -width * 0.05,
                    bottom: height * 0.18,
                    child: _GlowCircle(size: width * 0.22, opacity: 0.10),
                  ),
                  Positioned(
                    top: height * 0.18,
                    right: -width * 0.06,
                    child: _GlowCircle(size: width * 0.34, opacity: 0.08),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: height * 0.18),
                          _BrandMark(
                            size: brandSize.clamp(92.0, 132.0),
                            borderRadius: brandRadius.clamp(28.0, 40.0),
                          ),
                          SizedBox(height: height * 0.04),
                          Text(
                            'EduPath',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: titleSize.clamp(34.0, 52.0),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          SizedBox(height: height * 0.01),
                          Text(
                            'Unlock your potential',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: subtitleSize.clamp(15.0, 22.0),
                                  letterSpacing: 0.2,
                                ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: width * 0.08,
                            height: width * 0.08,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.035),
                          Padding(
                            padding: EdgeInsets.only(bottom: height * 0.04),
                            child: Text(
                              'PREPARING YOUR JOURNEY',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: footerSize.clamp(12.0, 16.0),
                                    letterSpacing: 2.8,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.borderRadius});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF2D2474).withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 38,
          color: Color(0xFF514BEF),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
