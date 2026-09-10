import 'package:flutter/material.dart';

/// Central light-mode palette for the app. Screens historically hardcoded
/// dark hex values inline; these named tokens are the light equivalents so
/// new code (and refactors) can stay consistent.
class AppColors {
  // Surfaces
  static const Color bg = Color(0xFFEEF2F6); // page background
  static const Color surface = Color(0xFFFFFFFF); // cards, panels
  static const Color surfaceAlt = Color(0xFFF1F5F9); // inputs, raised tiles
  static const Color border = Color(0x14000000); // hairline borders

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textFaint = Color(0xFF94A3B8);

  // Brand / accents
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color accent = Color(0xFF2563EB);

  // Status
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerText = Color(0xFFDC2626);
  static const Color success = Color(0xFF10B981);
  static const Color successText = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
}
