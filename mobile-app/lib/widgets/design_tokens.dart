import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens from "The Culinary Atelier — Vibrant Orange" design system.
/// Reference: design-artifacts/D-Design-System/mobile-appdesign/New/culinary_atelier/DESIGN.md
abstract final class MitablColors {
  // ── Primary Brand ──
  static const Color primary = Color(0xFFEA580C); // Vibrant Orange
  static const Color primaryContainer = Color(0xFFEA580C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFEDD5);
  static const Color primaryFixedDim = Color(0xFFFFB599);
  static const Color onPrimaryFixed = Color(0xFF431407);
  static const Color onPrimaryFixedVariant = Color(0xFF9A3412);
  static const Color inversePrimary = Color(0xFFFFB599);

  // ── Secondary (Slate) ──
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF64748B);
  static const Color secondaryFixed = Color(0xFFE2E8F0);
  static const Color secondaryFixedDim = Color(0xFFCBD5E1);
  static const Color onSecondaryFixed = Color(0xFF0F172A);
  static const Color onSecondaryFixedVariant = Color(0xFF475569);

  // ── Tertiary (Sage Green) ──
  static const Color tertiary = Color(0xFF506140);
  static const Color tertiaryContainer = Color(0xFF687A57);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFF9FFEC);
  static const Color tertiaryFixed = Color(0xFFD5E9BF);
  static const Color tertiaryFixedDim = Color(0xFFB9CDA4);
  static const Color onTertiaryFixed = Color(0xFF111F05);
  static const Color onTertiaryFixedVariant = Color(0xFF3B4C2C);

  // ── Surfaces ──
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF8FAFC);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFDFE9FA);
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F5F9);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceTint = Color(0xFFEA580C);
  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF0F172A);

  // ── Text / Semantic ──
  static const Color onSurface = Color(0xFF0F172A); // Slate 900
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);
  static const Color inverseSurface = Color(0xFF1E293B);

  // ── Outline ──
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // ── Status ──
  static const Color accent = Color(0xFF506140); // Sage green (tertiary)
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // ── Gradient ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
}

abstract final class MitablRadius {
  /// 20px – ALL content cards
  static const double card = 20.0;

  /// 100px – Pill-shaped buttons
  static const double pill = 100.0;

  /// 8px – Nested quick-info chips inside cards
  static const double chipSmall = 8.0;

  /// 16px – Input fields
  static const double input = 16.0;

  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius inputBorder = BorderRadius.all(Radius.circular(input));
}

abstract final class MitablSpacing {
  /// 22.4px – Vertical gap between list items (replaces 1px dividers)
  static const double listItem = 22.4;

  /// 48px – White-space breathing room around food photography
  static const double breathe = 48.0;

  /// 16px – Standard horizontal page padding
  static const double pagePadding = 16.0;

  /// 12px – Inner card padding
  static const double cardPadding = 12.0;
}

abstract final class MitablShadows {
  /// Ambient shadow for floating elements (FAB, popover).
  /// Most cards use tonal layering instead of shadows.
  static List<BoxShadow> ambient = [
    BoxShadow(
      color: MitablColors.onSurface.withValues(alpha: 0.06),
      blurRadius: 32,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ghost border for accessibility — outlineVariant at 15%.
  static Border ghostBorder = Border.all(
    color: MitablColors.outlineVariant.withValues(alpha: 0.15),
  );
}

abstract final class MitablGlass {
  /// Glassmorphism filter for sticky headers / floating nav.
  static ImageFilter blur = ImageFilter.blur(sigmaX: 20, sigmaY: 20);

  /// Surface color at 80% opacity for glass background.
  static Color background = MitablColors.surface.withValues(alpha: 0.80);
}
