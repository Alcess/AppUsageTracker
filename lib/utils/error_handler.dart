import 'package:flutter/material.dart';

/// Common error handling patterns to reduce boilerplate
class ErrorHandler {
  /// Handle errors with standardized logging and user feedback
  static void handle(
    BuildContext? context,
    String operation,
    Object error, {
    String? userMessage,
    bool showSnackBar = true,
  }) {
    // Log the error
    debugPrint('Error in $operation: $error');

    // Show user feedback if context provided
    if (context != null && showSnackBar) {
      final message = userMessage ?? 'An error occurred during $operation';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle errors with custom action
  static void handleWithAction(
    BuildContext context,
    String operation,
    Object error, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    debugPrint('Error in $operation: $error');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error in $operation'),
        backgroundColor: Colors.red,
        action: actionLabel != null && action != null
            ? SnackBarAction(label: actionLabel, onPressed: action)
            : null,
      ),
    );
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show loading dialog
  static void showLoading(
    BuildContext context,
    String message, {
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
