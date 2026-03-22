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
          outlineVariant: AppColors.lightBorder.withValues(alpha: 0.5),
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: _textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary),
        appBarTheme: AppBarTheme(
          // backgroundColor: AppColors.lightBackground,
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          // foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.headlineSmall.copyWith(
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
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.lightBorder),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.lightBorder, width: 1),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.lightBorder.withValues(alpha: 0.6),
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.lightTextPrimary,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightSurface),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.08),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(color: AppColors.primary);
            }
            return AppTextStyles.labelSmall.copyWith(color: AppColors.lightTextSecondary);
          }),
          height: 72,
          elevation: 0,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          titleTextStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.lightTextPrimary),
          subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
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
          outlineVariant: AppColors.darkBorder.withValues(alpha: 0.5),
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        inputDecorationTheme: _inputDecoration(
          borderColor: AppColors.darkBorder,
          fillColor: AppColors.darkSurface,
          textColor: AppColors.darkTextPrimary,
          hintColor: AppColors.darkTextTertiary,
        ),
        filledButtonTheme: _filledButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.darkBorder),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.darkBorder.withValues(alpha: 0.6),
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkSurfaceVariant,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(color: AppColors.primaryLight);
            }
            return AppTextStyles.labelSmall.copyWith(color: AppColors.darkTextSecondary);
          }),
          height: 72,
          elevation: 0,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          titleTextStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.darkTextPrimary),
          subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.darkTextSecondary),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color borderColor) => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.labelLarge,
          elevation: 0,
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
}
