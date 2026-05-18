import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _identifierError;
  String? _answerError;
  String? _passwordError;
  String? _generalError;

  Future<void> _handleReset() async {
    setState(() {
      _identifierError = _identifierController.text.isEmpty
          ? "Required field"
          : null;
      _answerError = _answerController.text.isEmpty ? "Required field" : null;
      _passwordError = _newPasswordController.text.isEmpty
          ? "Required field"
          : null;
      _generalError = null;
    });

    if (_identifierError != null ||
        _answerError != null ||
        _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await api.resetPassword(
        username: _identifierController.text,
        securityAnswer: _answerController.text,
        newPasswordPlain: _newPasswordController.text,
      );
      if (!mounted) return;

      FeedbackUtils.show(
        context,
        title: "Success",
        message:
            "Your password has been reset successfully. You can now log in.",
        type: FeedbackType.success,
      );
      context.pop();
    } catch (e) {
      setState(() {
        _generalError = e.toString().replaceAll("Panic:", "");
      });
      Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _generalError = null);
      });
    } finally {
      setState(() => _isLoading = false);
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
                padding: const EdgeInsets.all(40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          overlayColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "RESET PASSWORD",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Verify your identity to secure your account",
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildTextField(
                        controller: _identifierController,
                        label: "Student ID / Email",
                        icon: Icons.person_outline,
                        errorText: _identifierError,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _answerController,
                        label: "Security Answer",
                        icon: Icons.question_answer_outlined,
                        errorText: _answerError,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _newPasswordController,
                        label: "New Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        errorText: _passwordError,
                        onToggleVisibility: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
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

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            overlayColor: Colors.transparent,
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
                                  "UPDATE PASSWORD",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/logo/jhcsc.png",
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
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
          ),
        ),
      ],
    );
  }
}
