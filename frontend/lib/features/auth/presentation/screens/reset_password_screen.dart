import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_header.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final client = Supabase.instance.client;
    try {
      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingHorizontal,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(),
                  AppSpacing.gapLg,
                  Text(
                    'Reset your password to regain access to your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  AppSpacing.gapXl,

                  // New Password
                  AuthTextField(
                    controller: _passwordController,
                    labelText: 'New Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return AppStrings.requiredPassword;
                      if (value.length < 6) return AppStrings.passwordTooShort;
                      return null;
                    },
                  ),
                  AppSpacing.gapMd,

                  // Confirm Password
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: AppStrings.confirmPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value != _passwordController.text) return AppStrings.passwordMismatch;
                      return null;
                    },
                  ),
                  AppSpacing.gapLg,

                  // Submit
                  AuthSubmitButton(
                    label: 'Update Password',
                    isLoading: false, // For simplicity
                    onPressed: _handleUpdatePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
