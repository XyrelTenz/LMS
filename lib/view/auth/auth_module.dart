import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/view/auth/presentation/view/signin_screen.dart';
import 'package:librarymanagementsystem/view/auth/presentation/view/signup_screen.dart';
import 'package:librarymanagementsystem/view/auth/presentation/view/splash_screen.dart';
import 'package:librarymanagementsystem/view/auth/presentation/view/forgot_password_screen.dart';

class AuthModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      name: "SplashScreen",
      '/',
      child: (context, GoRouterState state) => const SplashScreen(),
    ),
    ChildRoute(
      name: "Signin",
      '/auth/signin',
      child: (context, GoRouterState state) => const SigninScreen(),
    ),
    ChildRoute(
      name: "Signup",
      "/auth/signup",
      child: (context, GoRouterState state) => const SignupScreen(),
    ),
    ChildRoute(
      name: "ForgotPassword",
      "/auth/forgot_password",
      child: (context, GoRouterState state) => const ForgotPasswordScreen(),
    ),
  ];
}
