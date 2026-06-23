import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/service/api_service.dart';
import 'core/service/app_route_observer.dart';
import 'core/service/session_manager.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Get.putAsync(() => SessionManager().init());
  Get.put(ApiService());
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProfileProvider())],
      child: const EduPathApp(),
    ),
  );
}

class EduPathApp extends StatelessWidget {
  const EduPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduPath',
      initialRoute: AppRoutes.splash,
      navigatorObservers: [appRouteObserver],
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
