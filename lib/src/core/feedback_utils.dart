import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';

enum FeedbackType { success, error, info, warning }

class FeedbackUtils {
  /// Displays a premium custom modal for feedback instead of a standard SnackBar.
  static Future<T?> show<T>(
    BuildContext context, {
    required String message,
    String title = "Notification",
    FeedbackType type = FeedbackType.info,
  }) {
    final Color primaryColor = _getColor(type);
    final IconData icon = _getIcon(type);

    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return AppColors.error;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.info:
        return AppColors.primary;
    }
  }

  static IconData _getIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case FeedbackType.error:
        return Icons.error_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }
}
