import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/service/analytics_service.dart';
import 'core/service/api_service.dart';
import 'core/service/app_route_observer.dart';
import 'core/service/session_manager.dart';
import 'firebase_options.dart';
import 'modules/fun_fact/controller/fun_fact_controller.dart';
import 'modules/auth/views/create_account_screen.dart';
import 'modules/auth/views/forgot_password_views.dart';
import 'modules/auth/views/login_screen.dart';
import 'modules/dashboard_vc/views/dashboard_tabbar_views_screen.dart';
import 'modules/leaderboard/views/leaderboard_views.dart';
import 'modules/onboard/views/onboard_view.dart';
import 'modules/splash/views/splash_view.dart';
import 'modules/student_profile_setup/student_profile_setup_views.dart';
import 'routes/app_routes.dart';

import 'package:provider/provider.dart';
import 'core/data/user_profile_provider.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Guarded so a not-yet-configured platform (e.g. iOS before the
    // GoogleService-Info.plist is added) can't crash app launch — Firebase
    // simply stays off there.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Route uncaught Flutter framework errors to Crashlytics.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Route uncaught async/platform errors to Crashlytics.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Only now is it safe to touch FirebaseAnalytics.
      AnalyticsService.instance.enable();
    } catch (e) {
      // Not configured on this platform yet (e.g. iOS before its
      // GoogleService-Info.plist is added) — run without Firebase.
      debugPrint('Firebase not initialized: $e');
    }

    await Get.putAsync(() => SessionManager().init());
    Get.put(ApiService());
    // Outlives the dashboard so the story rings keep their seen state when the
    // Home tab is rebuilt.
    Get.put(FunFactController(), permanent: true);
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ],
        child: const EduPathApp(),
      ),
    );
  }, (error, stack) {
    // Print first, always. Crashlytics is optional: when Firebase failed to
    // initialise, touching it here throws 'No Firebase App' and that becomes
    // the only error anyone sees — the actual bug is lost.
    debugPrint('UNCAUGHT ERROR: $error\n$stack');
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

class EduPathApp extends StatelessWidget {
  const EduPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduPath',
      initialRoute: AppRoutes.splash,
      navigatorObservers: [appRouteObserver, AnalyticsService.instance.observer],
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashView()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordViews(),
        ),
        GetPage(
          name: AppRoutes.createAccount,
          page: () => const CreateAccountScreen(),
        ),
        GetPage(name: AppRoutes.onboarding, page: () => const OnboardView()),
        GetPage(
          name: AppRoutes.studentProfileSetup,
          page: () => const StudentProfileSetupViews(),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const DashboardTabbarViewsScreen(),
        ),
        GetPage(
          name: AppRoutes.leaderboard,
          page: () => const LeaderboardViews(),
        ),
      ],
      theme: ThemeData(
        fontFamily: 'Lexend',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5F59EF)),
        useMaterial3: true,
      ),
    );
  }
}
