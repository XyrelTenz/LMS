import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/src/core/session_manager.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = await SessionManager.getUser();
    if (!mounted) return;

    if (user != null) {
      final role = user['role'] as String;
      if (role.toLowerCase().contains("librarian")) {
        context.go('/librarian/overview');
      } else {
        context.go('/student/library_catalog');
      }
    } else {
      context.go('/auth/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/logo/jhcsc.png',
                width: 180,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.library_books_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
