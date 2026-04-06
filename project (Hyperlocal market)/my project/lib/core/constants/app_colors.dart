import 'package:flutter/material.dart';

/// App color palette for HyperLocal Market.
/// 
/// Defines all colors used throughout the application with semantic naming.
/// Primary color is generated from seed color 0xFF2E7D32 (green).
abstract final class AppColors {
  /// Primary brand color - deep green for HyperLocal Market.
  /// Used for main CTAs, app bar, and branding elements.
  static const Color primary = Color(0xFF2E7D32);

  /// Primary light variant for hover/pressed states.
  static const Color primaryLight = Color(0xFF66BB6A);

  /// Primary dark variant for emphasis.
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Secondary accent color - complementary to primary.
  static const Color secondary = Color(0xFF00897B);

  /// Secondary light variant.
  static const Color secondaryLight = Color(0xFF26A69A);

  /// Error color for validation errors, failed states, deletions.
  static const Color error = Color(0xFFD32F2F);

  /// Error light variant.
  static const Color errorLight = Color(0xFFEF5350);

  /// Warning color for alerts, cautions, and attention states.
  static const Color warning = Color(0xFFFFA726);

  /// Warning light variant.
  static const Color warningLight = Color(0xFFFFB74D);

  /// Success color for confirmations, completed states, verified actions.
  static const Color success = Color(0xFF388E3C);

  /// Success light variant.
  static const Color successLight = Color(0xFF81C784);

  /// Background color for screens and sections.
  static const Color background = Color(0xFFFAFAFA);

  /// Surface color for cards, sheets, and elevated containers.
  static const Color surface = Color(0xFFFFFFFF);

  /// Divider and border color for separating elements.
  static const Color divider = Color(0xFFE0E0E0);

  /// Text color for primary text content (headings, body text).
  static const Color textPrimary = Color(0xFF212121);

  /// Text color for secondary text (hints, labels).
  static const Color textSecondary = Color(0xFF757575);

  /// Text color for disabled or inactive text.
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// Text color for text on colored backgrounds (inverse).
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Icon color for primary icons.
  static const Color iconPrimary = Color(0xFF424242);

  /// Icon color for secondary icons.
  static const Color iconSecondary = Color(0xFF9E9E9E);

  /// Transparent color placeholder.
  static const Color transparent = Color(0x00000000);

  /// Overlay color for dimmed overlays (e.g., modals, bottom sheets).
  static const Color overlay = Color(0x80000000);

  /// Mild background tint for alternate sections.
  static const Color backgroundTint = Color(0xFFF1F8E9);
}
