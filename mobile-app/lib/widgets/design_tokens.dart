import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens from the "Warm Tactile Mitabl" design system.
/// Reference: design-artifacts/D-Design-System/mobile-appdesign/warm_tactile_mitabl/DESIGN.md
abstract final class MitablColors {
  // ── Primary Brand ──
  static const Color primary = Color(0xFF9C3E20); // Roasted Earth
  static const Color primaryContainer = Color(0xFFBC5636); // Warm accent
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Secondary ──
  static const Color secondaryContainer = Color(0xFFCCE7C3); // Herb green
  static const Color onSecondaryContainer = Color(0xFF51694C);

  // ── Tertiary ──
  static const Color tertiaryFixedDim = Color(0xFFD9C2B6); // Unselected chips

  // ── Surfaces ──
  static const Color surface = Color(0xFFFCF9F4); // Warm Oat – primary canvas
  static const Color surfaceContainerLow = Color(0xFFF6F3EE); // Subtle grouping
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Lifted cards
  static const Color surfaceBright = Color(0xFFFCF9F4); // Modals

  // ── Text / Semantic ──
  static const Color onSurface = Color(0xFF1C1C19); // Roasted Espresso
  static const Color onSurfaceVariant = Color(0xFF56423C); // Secondary text
  static const Color outlineVariant = Color(0xFFDDC0B8); // Ghost borders

  // ── Status ──
  static const Color accent = Color(0xFF10B981); // Emerald green
  static const Color error = Color(0xFFDC2626);

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
