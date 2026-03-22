import 'package:flutter/material.dart';

/// Chronicle Design System — Color Palette
/// Neutral base + deep indigo accent (Notion/Linear inspired)
abstract final class AppColors {
  // ── Brand / Accent ──
  static const Color primary = Color(0xFF4F46E5);       // Indigo-600
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo-400
  static const Color primaryDark = Color(0xFF3730A3);    // Indigo-800

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);       // Emerald-500
  static const Color warning = Color(0xFFF59E0B);       // Amber-500
  static const Color error = Color(0xFFEF4444);         // Rose-500
  static const Color info = Color(0xFF0EA5E9);          // Sky-500

  // ── Light Theme Surface ──
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color lightBorder = Color(0xFFE2E8F0);    // Slate-200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate-900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate-600
  static const Color lightTextTertiary = Color(0xFF94A3B8);  // Slate-400

  // ── Dark Theme Surface ──
  static const Color darkBackground = Color(0xFF020617); // Slate-950
  static const Color darkSurface = Color(0xFF0F172A);    // Slate-900
  static const Color darkSurfaceVariant = Color(0xFF1E293B); // Slate-800
  static const Color darkBorder = Color(0xFF334155);     // Slate-700
  static const Color darkTextPrimary = Color(0xFFF8FAFC);  // Slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color darkTextTertiary = Color(0xFF64748B);  // Slate-500
}
