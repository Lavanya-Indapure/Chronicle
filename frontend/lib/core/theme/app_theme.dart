import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Chronicle Design System — Theme
/// Centralized ThemeData for light and dark modes.
abstract final class AppTheme {
  // ── Light Theme ──
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primaryLight,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          error: AppColors.error,
          outline: AppColors.lightBorder,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightSurface,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: AppTextStyles.titleLarge.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
        inputDecorationTheme: _inputDecoration(
          borderColor: AppColors.lightBorder,
          fillColor: AppColors.lightSurface,
          textColor: AppColors.lightTextPrimary,
          hintColor: AppColors.lightTextTertiary,
        ),
        filledButtonTheme: _filledButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: const BorderSide(color: AppColors.lightBorder, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          ),
        ),
      );

  // ── Dark Theme ──
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: AppColors.darkBackground,
          secondary: AppColors.primary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          error: AppColors.error,
          outline: AppColors.darkBorder,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: AppTextStyles.titleLarge.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        inputDecorationTheme: _inputDecoration(
          borderColor: AppColors.darkBorder,
          fillColor: AppColors.darkSurfaceVariant,
          textColor: AppColors.darkTextPrimary,
          hintColor: AppColors.darkTextTertiary,
        ),
        filledButtonTheme: _filledButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
          elevation: 0,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          ),
        ),
      );

  // ── Shared helpers ──
  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
      );

  static InputDecorationTheme _inputDecoration({
    required Color borderColor,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: hintColor),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: hintColor),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      );
}
