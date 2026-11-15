import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'package:chronicle/core/constants/app_spacing.dart';

/// Chronicle Design System — Theme
/// Centralized ThemeData for light and dark modes.
///
/// Both modes share one builder; only the [_Palette] differs.
/// - Dark: deep navy surfaces, lemon accent as `primary`.
/// - Light: pale blue-grey background, white cards, navy `primary`
///   (lemon stays as `primaryContainer` so hero cards look the same in both).
abstract final class AppTheme {
  static ThemeData get light => _build(_Palette.light);
  static ThemeData get dark => _build(_Palette.dark);

  static ThemeData _build(_Palette p) {
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.info,
      onSecondary: AppColors.darkTextPrimary,
      secondaryContainer: p.surfaceVariant,
      onSecondaryContainer: p.textPrimary,
      tertiary: AppColors.warning,
      onTertiary: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.darkTextPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceVariant,
      surfaceContainerHighest: p.surfaceHigh,
      outline: p.border,
      outlineVariant: p.border,
      inverseSurface: p.textPrimary,
      onInverseSurface: p.background,
      shadow: AppColors.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: _textTheme(p.textPrimary, p.textSecondary),
      iconTheme: IconThemeData(color: p.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: p.textPrimary),
      ),
      inputDecorationTheme: _inputDecoration(p),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusPill),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusPill),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusPill),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        // Stadium = circle on regular FABs, pill on .extended ones.
        shape: StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
      ),
      chipTheme: ChipThemeData(
        // surfaceVariant (not surface) so unselected chips stay visible on
        // bottom sheets, whose background is surface.
        backgroundColor: p.surfaceVariant,
        selectedColor: p.textPrimary,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusPill),
        // Selected chips are filled with textPrimary, so their label and
        // checkmark must flip to the background colour to stay readable.
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected) ? p.background : p.textPrimary,
          ),
        ),
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: p.background),
        checkmarkColor: p.background,
        iconTheme: IconThemeData(color: p.textPrimary, size: AppSpacing.md + 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: p.background),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: p.textPrimary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceVariant,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceVariant,
        circularTrackColor: p.surfaceVariant,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onPrimary : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.surfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),
    );
  }

  // ── Shared helpers ──
  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: primary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
      );

  static InputDecorationTheme _inputDecoration(_Palette p) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: p.textTertiary),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
      prefixIconColor: p.textSecondary,
      suffixIconColor: p.textSecondary,
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(p.primary, 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.5),
    );
  }
}

/// Per-mode surface/text colors fed into [AppTheme._build].
class _Palette {
  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const _Palette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  static const light = _Palette(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.lightSurface,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    surfaceHigh: AppColors.lightSurfaceHigh,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
  );

  static const dark = _Palette(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: AppColors.ink,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    surfaceHigh: AppColors.darkSurfaceHigh,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
  );
}
