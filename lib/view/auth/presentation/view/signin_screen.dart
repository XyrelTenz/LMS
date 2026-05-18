import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/src/core/session_manager.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart';
import 'package:librarymanagementsystem/src/core/face_recognition_utils.dart';
import 'package:librarymanagementsystem/src/rust/api/auth_api.dart' as auth_api;

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = "Student";
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _identifierError;
  String? _passwordError;
  String? _generalError;

  Future<void> _handleLogin() async {
    setState(() {
      _identifierError = _identifierController.text.isEmpty
          ? "This field is required"
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? "Password is required"
          : null;
      _generalError = null;
    });

    if (_identifierError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    try {
      final user = await api.loginUser(
        identifier: _identifierController.text,
        passwordPlain: _passwordController.text,
      );

      final userRoleStr = _selectedRole.toLowerCase();
      if (user.role.name.toLowerCase() != userRoleStr) {
        throw "Account not found for this role";
      }

      await SessionManager.saveUser(user);
      if (!mounted) return;

      if (user.role == UserRole.librarian) {
        context.go('/librarian/overview');
      } else {
        context.go('/student/library_catalog');
      }
    } catch (e) {
      setState(() {
        _generalError = e.toString().replaceAll("Panic:", "");
      });
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _generalError = null);
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFaceSignIn() async {
    final userId = await showDialog<String>(
      context: context,
      builder: (context) => const FaceScannerDialog(isRegistration: false),
    );

    if (userId != null) {
      setState(() => _isLoading = true);
      try {
        final user = await auth_api.getUserById(id: userId);

        final userRoleStr = _selectedRole.toLowerCase();
        if (user.role.name.toLowerCase() != userRoleStr) {
          throw "Face ID matched, but not for this role";
        }

        await SessionManager.saveUser(user);
        if (!mounted) return;

        if (user.role == UserRole.librarian) {
          context.go('/librarian/overview');
        } else {
          context.go('/student/library_catalog');
        }
      } catch (e) {
        setState(() => _generalError = e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Expanded(
            flex: isDesktop ? 6 : 10,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 40,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "WELCOME BACK",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in",
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildDropdownField(
                        label: "Role",
                        icon: Icons.work_outline,
                        value: _selectedRole,
                        items: ["Student", "Librarian"],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _identifierController,
                        label: _selectedRole == "Student"
                            ? "Student ID"
                            : "Librarian Email",
                        icon: _selectedRole == "Student"
                            ? Icons.badge_outlined
                            : Icons.email_outlined,
                        errorText: _identifierError,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        errorText: _passwordError,
                        onToggleVisibility: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              context.push('/auth/forgot_password'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary.withValues(
                              alpha: 0.8,
                            ),
                            overlayColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (_generalError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _generalError!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            overlayColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "SIGN IN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleFaceSignIn,
                          icon: const Icon(Icons.face_retouching_natural),
                          label: const Text(
                            "CONTINUE WITH FACE ID",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/auth/signup'),
                            style: TextButton.styleFrom(
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
          ),

          // Right Side: Branding (Desktop Only)
          if (isDesktop) Expanded(flex: 4, child: _buildBrandingSection()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    String? errorText,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          keyboardType: label.contains("ID")
              ? TextInputType.number
              : TextInputType.emailAddress,
          inputFormatters: label.contains("ID")
              ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
              : <TextInputFormatter>[],
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            errorText: errorText,
            prefixIcon: Icon(
              icon,
              color: errorText != null
                  ? AppColors.error
                  : AppColors.primary.withValues(alpha: 0.7),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.3),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.primary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textDark),
          iconEnabledColor: AppColors.textLight,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.3),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          items: items
              .map<DropdownMenuItem<String>>(
                (i) => DropdownMenuItem(value: i, child: Text(i)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBrandingSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo/jhcsc.png',
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.library_books_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
