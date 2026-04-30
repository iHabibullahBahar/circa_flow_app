import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:circa_flow_main/src/routing/app_routes.dart';

import 'package:circa_flow_main/src/features/auth/presentation/screens/login_screen.dart';
import 'package:circa_flow_main/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:circa_flow_main/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:circa_flow_main/src/features/home/presentation/screens/home_page.dart';
import 'package:circa_flow_main/src/features/onboarding/presentation/screens/onboarding_page.dart';


class AppRouter {
  static List<GetPage> get getPages => [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
    ),
  ];
}
