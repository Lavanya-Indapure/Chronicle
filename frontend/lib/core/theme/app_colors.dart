import 'package:flutter/material.dart';

/// Chronicle Design System — Color Palette
/// Neutral base + deep indigo accent (Notion/Linear inspired)
abstract final class AppColors {
  // ── Brand / Accent ──
  static const Color primary = Color(0xFF6366F1);       // Indigo-500
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo-400
  static const Color primaryDark = Color(0xFF4F46E5);    // Indigo-600

  // ── Semantic ──
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Light Theme Surface ──
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightTextTertiary = Color(0xFFA1A1AA);

  // ── Dark Theme Surface ──
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkSurfaceVariant = Color(0xFF27272A);
  static const Color darkBorder = Color(0xFF3F3F46);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);
}
