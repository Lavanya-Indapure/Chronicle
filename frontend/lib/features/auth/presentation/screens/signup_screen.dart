import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chronicle/core/constants/app_spacing.dart';
import 'package:chronicle/core/constants/app_strings.dart';
import 'package:chronicle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:chronicle/features/auth/presentation/widgets/auth_header.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: AppStrings.selectDob,
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dob: _selectedDob,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.accountCreated)),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingHorizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.gapLg,
                    const AuthHeader(),
                    AppSpacing.gapXl,

                    // First Name
                    AuthTextField(
                      controller: _firstNameController,
                      labelText: AppStrings.firstName,
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.requiredFirstName;
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    // Last Name
                    AuthTextField(
                      controller: _lastNameController,
                      labelText: AppStrings.lastName,
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.requiredLastName;
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    // Email
                    AuthTextField(
                      controller: _emailController,
                      labelText: AppStrings.email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.requiredEmail;
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return AppStrings.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapMd,

                    // DOB (Optional)
                    AuthTextField(
                      controller: TextEditingController(
                        text: _selectedDob != null
                            ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                            : '',
                      ),
                      labelText: AppStrings.dateOfBirth,
                      prefixIcon: Icons.cake_outlined,
                      readOnly: true,
                      onTap: _pickDob,
                    ),
                    AppSpacing.gapMd,

                    // Password
                    AuthTextField(
                      controller: _passwordController,
                      labelText: AppStrings.password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.requiredPassword;
                        }
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
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return AppStrings.passwordMismatch;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSignup(),
                    ),
                    AppSpacing.gapLg,

                    // Submit
                    AuthSubmitButton(
                      label: AppStrings.createAccount,
                      isLoading: isLoading,
                      onPressed: _handleSignup,
                    ),
                    AppSpacing.gapXl,

                    // Switch to login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.haveAccount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(AppStrings.login),
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
