import 'package:flutter/material.dart';

/// Centralized design-token color palette.
///
/// Light mode: warm ivory background, soft pastel orange accent.
/// Dark mode: pleasant graphite background, same soft pastel orange accent.
/// All colors are intentionally muted/pastel — no neon, no pure black/white.
class AppColors {
  AppColors._();

  // Shared accent — consistent across both themes.
  // Slightly richer/warmer than the original pastel tone for a livelier
  // feel, while staying well short of neon/saturated — still easy on the
  // eyes for long sessions.
  static const Color primaryOrange = Color(0xFFF5934F);
  static const Color primaryOrangeDark = Color(0xFFE27A32);
  static const Color secondaryGreen = Color(0xFF7CAA76);

  // Light theme
  static const Color lightBackground = Color(0xFFFDF6EA);
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCream = Color(0xFFF6E9D3);
  static const Color lightBeige = Color(0xFFEDDDBC);
  static const Color lightWarmGray = Color(0xFF9C9184);
  static const Color lightTextPrimary = Color(0xFF3A3229);
  static const Color lightTextSecondary = Color(0xFF7D7365);
  static const Color lightBorder = Color(0xFFEAE0CF);
  static const Color lightDanger = Color(0xFFD97A6C);

  // Dark theme
  static const Color darkBackground = Color(0xFF201E1B);
  static const Color darkSurface = Color(0xFF2A2724);
  static const Color darkCard = Color(0xFF322E2A);
  static const Color darkCream = Color(0xFF3A352F);
  static const Color darkBeige = Color(0xFF423C34);
  static const Color darkWarmGray = Color(0xFFA69C8D);
  static const Color darkTextPrimary = Color(0xFFF3EEE6);
  static const Color darkTextSecondary = Color(0xFFB8AFA1);
  static const Color darkBorder = Color(0xFF433D36);
  static const Color darkDanger = Color(0xFFE2958A);

  // Difficulty tag colors (slightly richer than before, still soft via
  // alpha overlays — work on both themes)
  static const Color easyGreen = Color(0xFF7CAA76);
  static const Color mediumOrange = Color(0xFFE0A038);
  static const Color hardRed = Color(0xFFDD7864);

  // Category tints (a touch more saturated than the original pastel set,
  // used for pantry categories)
  static const Color tintVegetables = Color(0xFF8DBB7A);
  static const Color tintMeat = Color(0xFFDB8F75);
  static const Color tintDairy = Color(0xFF97C0DB);
  static const Color tintFruits = Color(0xFFE0A038);
  static const Color tintGrains = Color(0xFFD9BC72);
  static const Color tintPantry = Color(0xFFB7A184);
}
