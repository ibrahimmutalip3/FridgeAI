import 'package:flutter/material.dart';

/// Centralized design-token color palette.
///
/// Light mode: warm ivory background, soft pastel orange accent.
/// Dark mode: pleasant graphite background, same soft pastel orange accent.
/// All colors are intentionally muted/pastel — no neon, no pure black/white.
class AppColors {
  AppColors._();

  // Shared accent — consistent across both themes.
  static const Color primaryOrange = Color(0xFFF3A468);
  static const Color primaryOrangeDark = Color(0xFFE0894B);
  static const Color secondaryGreen = Color(0xFF8FAE8B);

  // Light theme
  static const Color lightBackground = Color(0xFFFBF5EC);
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCream = Color(0xFFF3E9D8);
  static const Color lightBeige = Color(0xFFEADFC8);
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

  // Difficulty tag colors (muted, work on both themes via alpha overlays)
  static const Color easyGreen = Color(0xFF8FAE8B);
  static const Color mediumOrange = Color(0xFFE0A75C);
  static const Color hardRed = Color(0xFFD97A6C);

  // Category tints (muted pastel, used for pantry categories)
  static const Color tintVegetables = Color(0xFF9BB98C);
  static const Color tintMeat = Color(0xFFD79A87);
  static const Color tintDairy = Color(0xFFA9C4D6);
  static const Color tintFruits = Color(0xFFE0A75C);
  static const Color tintGrains = Color(0xFFD8C08A);
  static const Color tintPantry = Color(0xFFBBA98F);
}
