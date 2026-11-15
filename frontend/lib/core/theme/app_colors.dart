import 'package:flutter/material.dart';

/// Chronicle Design System — Color Palette
/// Deep navy base + soft lemon accent, with a vivid chart palette.
abstract final class AppColors {
  // ── Brand / Accent ──
  static const Color accent = Color(0xFFF4F57F); // Soft lemon — hero cards, primary action
  static const Color accentDark = Color(0xFFE2E35C);
  static const Color ink = Color(0xFF141A2E); // Deep navy — text/icons on accent

  // ── Semantic ──
  static const Color success = Color(0xFF4CC86A);
  static const Color warning = Color(0xFFFF9447);
  static const Color error = Color(0xFFE5606F);
  static const Color info = Color(0xFF2F8CFF);

  // ── Chart / Category palette (works on both navy and light surfaces) ──
  static const Color chartBlue = Color(0xFF2F8CFF);
  static const Color chartLemon = Color(0xFFE6BE2E); // Deeper than [accent] so it reads on light surfaces too
  static const Color chartOrange = Color(0xFFFF8A3D);
  static const Color chartOrchid = Color(0xFFC86DD7);
  static const Color chartGreen = Color(0xFF4CC86A);
  static const Color chartTeal = Color(0xFF2EC4C9);
  static const Color chartCoral = Color(0xFFE5606F);

  static const List<Color> chartPalette = [
    chartBlue,
    chartLemon,
    chartOrange,
    chartOrchid,
    chartGreen,
    chartTeal,
    chartCoral,
  ];

  // ── Light Theme Surface ──
  static const Color lightBackground = Color(0xFFE9EEF5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF2F5FA);
  static const Color lightSurfaceHigh = Color(0xFFE3E9F2);
  static const Color lightBorder = Color(0xFFDCE3ED);
  static const Color lightTextPrimary = Color(0xFF141A2E);
  static const Color lightTextSecondary = Color(0xFF5B6480);
  static const Color lightTextTertiary = Color(0xFF8E96AD);

  // ── Dark Theme Surface ──
  static const Color darkBackground = Color(0xFF131A2D);
  static const Color darkSurface = Color(0xFF1E2640);
  static const Color darkSurfaceVariant = Color(0xFF283152);
  static const Color darkSurfaceHigh = Color(0xFF323C60);
  static const Color darkBorder = Color(0xFF2C3554);
  static const Color darkTextPrimary = Color(0xFFF5F7FB);
  static const Color darkTextSecondary = Color(0xFFA3ABC4);
  static const Color darkTextTertiary = Color(0xFF6E7899);

  // ── Shadows ──
  static const Color shadow = Color(0x33000000);
}
