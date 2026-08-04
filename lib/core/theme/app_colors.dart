import 'package:flutter/material.dart';

/// Centralized Production-Ready Design System Colors & Gradients
class AppColors {
  /// Deep Indigo (#1E3A5F) — Main brand identity, nav bars, headers
  static const Color primary = Color(0xFF1E3A5F);

  /// Primary Light / Electric Sky (#2563EB)
  static const Color primaryLight = Color(0xFF2563EB);

  /// Marigold Amber (#F4A623) — Primary CTAs, active highlights
  static const Color accent = Color(0xFFF4A623);

  /// Golden Amber (#F59E0B) — CTA Gradient accent
  static const Color accentDark = Color(0xFFF59E0B);

  /// Ice Teal (#4FD1C5) — Secondary badges, quick stats
  static const Color secondary = Color(0xFF4FD1C5);

  /// Soft Cloud (#F8FAFC) — Light page background
  static const Color background = Color(0xFFF8FAFC);

  /// Midnight Navy (#0F172A) — Dark mode page background
  static const Color darkBackground = Color(0xFF0F172A);

  /// Dark Surface Slate (#1E293B) — Dark mode card background
  static const Color darkSurface = Color(0xFF1E293B);

  /// Charcoal Text (#2B2F33) — Primary body text
  static const Color text = Color(0xFF2B2F33);

  /// Muted Text (#6B7280) — Helper text
  static const Color textMuted = Color(0xFF6B7280);

  /// Dark Mode Muted Text (#94A3B8)
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// Success Emerald (#10B981) — Completed/Confirmed states
  static const Color success = Color(0xFF10B981);

  /// Error Rose (#EF4444) — Error/Cancellation states
  static const Color error = Color(0xFFEF4444);

  /// Surface Card Background (#FFFFFF)
  static const Color card = Colors.white;

  // --- Brand Gradients ---

  /// Deep Indigo to Midnight Header Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF0F2744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Marigold to Golden CTA Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF4A623), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success Mint Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
