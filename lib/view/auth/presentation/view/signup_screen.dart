import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:librarymanagementsystem/src/core/face_recognition_utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String _selectedRole = "Student";
  String _selectedQuestion = "What is your pet's name?";
  bool _isLoading = false;
  String? _fullNameError;
  String? _usernameError;
  String? _passwordError;
  String? _securityAnswerError;
  String? _generalError;

  final List<String> _questions = [
    "What is your pet's name?",
    "What is your mother's maiden name?",
    "What was your first school?",
    "What city were you born in?",
  ];

  Future<void> _handleSignup() async {
    final bool isLibrarian = _selectedRole == "Librarian";
    setState(() {
      _fullNameError = _fullNameController.text.isEmpty
          ? "Full name is required"
          : null;
      _usernameError = _usernameController.text.isEmpty
          ? "ID/Email is required"
          : null;
      _passwordError = _passwordController.text.isEmpty
          ? "Password is required"
          : null;
      _securityAnswerError =
          (!isLibrarian && _securityAnswerController.text.isEmpty)
          ? "Security answer is required"
          : null;
      _generalError = null;
    });

    if (_fullNameError != null ||
        _usernameError != null ||
        _passwordError != null ||
        _securityAnswerError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await api.registerUser(
        username: _usernameController.text,
        passwordPlain: _passwordController.text,
        fullName: _fullNameController.text,
        role: _selectedRole,
        securityQuestion: isLibrarian ? "None" : _selectedQuestion,
        securityAnswer: isLibrarian ? "None" : _securityAnswerController.text,
      );
      if (!mounted) return;

      FeedbackUtils.show(
        context,
        title: "Success!",
        message:
            "Your account has been created successfully. You can now log in.",
        type: FeedbackType.success,
      );
      context.pop();
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

  Future<void> _handleFaceRegistration() async {
    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = "ID/Email is required for Face ID setup");
      return;
    }

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => FaceScannerDialog(
        isRegistration: true,
        userId: _usernameController.text,
      ),
    );

    if (!mounted) return;

    if (success == true) {
      FeedbackUtils.show(
        context,
        title: "Face Registered",
        message: "Your biometric data has been saved securely.",
        type: FeedbackType.success,
      );
    }
  }

  /// Displays a success dialog after account creation.

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1000;

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
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join the JHCSC Library community today",
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _fullNameController,
                              label: "Full Name",
                              icon: Icons.person_outline,
                              errorText: _fullNameError,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _usernameController,
                              label: _selectedRole == "Librarian"
                                  ? "Email"
                                  : "School ID",
                              icon: _selectedRole == "Librarian"
                                  ? Icons.email_outlined
                                  : Icons.badge_outlined,
                              errorText: _usernameError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 16),

                      _buildDropdownField(
                        label: "Role",
                        icon: Icons.work_outline,
                        value: _selectedRole,
                        items: ["Student", "Librarian"],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                      ),

                      if (_selectedRole == "Student") ...[
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: "Security Question",
                          icon: Icons.help_outline,
                          value: _selectedQuestion,
                          items: _questions,
                          onChanged: (val) =>
                              setState(() => _selectedQuestion = val!),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _securityAnswerController,
                          label: "Security Answer",
                          icon: Icons.question_answer_outlined,
                          isPassword: true,
                          errorText: _securityAnswerError,
                        ),
                      ],
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
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
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
                                  "REGISTER NOW",
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
                          onPressed: _handleFaceRegistration,
                          icon: const Icon(Icons.face_unlock_outlined),
                          label: const Text(
                            "SET UP FACE ID (OPTIONAL)",
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
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            overlayColor: Colors.transparent,
                          ),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 15,
                              ),
                              children: [
                                TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
          if (isDesktop) Expanded(flex: 4, child: _buildBrandingSection()),
        ],
      ),
    );
  }

  /// Builds a customized text field with consistent styling.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? errorText,
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
          obscureText: isPassword,
          keyboardType: label == "School ID"
              ? TextInputType.number
              : (label == "Full Name"
                    ? TextInputType.name
                    : TextInputType.text),
          inputFormatters: label == "School ID"
              ? [FilteringTextInputFormatter.digitsOnly]
              : [],
          style: const TextStyle(color: AppColors.textDark),
          decoration: InputDecoration(
            errorText: errorText,
            hintText: "Enter $label",
            hintStyle: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.3),
            ),
            prefixIcon: Icon(
              icon,
              color: errorText != null
                  ? AppColors.error
                  : AppColors.primary.withValues(alpha: 0.7),
            ),
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

  /// Builds a customized dropdown field with consistent styling.
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
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Builds the side branding section with the college logo.
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
