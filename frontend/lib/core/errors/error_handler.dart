import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'app_exception.dart';

/// Maps raw exceptions to user-friendly [AppException] instances.
abstract final class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is supa.AuthException) {
      return AuthException(
        _mapAuthMessage(error.message),
        code: error.statusCode,
        originalError: error,
      );
    }
    if (error is AppException) return error;
    return AppException(
      'An unexpected error occurred',
      originalError: error,
    );
  }

  static String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) return 'Invalid email or password';
    if (lower.contains('email not confirmed')) return 'Please verify your email first';
    if (lower.contains('already registered')) return 'An account with this email already exists';
    if (lower.contains('rate limit')) return 'Too many attempts. Please try again later';
    return message;
  }

  /// Show a user-friendly error snackbar.
  static void showError(BuildContext context, dynamic error) {
    final appError = handle(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appError.message)),
    );
  }
}
