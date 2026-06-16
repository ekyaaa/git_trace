import 'package:flutter/material.dart';
import 'constants.dart';
import 'theme.dart';

/// Theme-aware color helper
/// Usage: final colors = ThemeColors.of(context);
class ThemeColors {
  final BuildContext context;
  final bool isDark;

  ThemeColors._(this.context) : isDark = Theme.of(context).brightness == Brightness.dark;

  /// Get ThemeColors from context
  factory ThemeColors.of(BuildContext context) {
    return ThemeColors._(context);
  }

  // ==================== BACKGROUND COLORS ====================
  Color get background => isDark ? AppColors.background : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.surface : AppColors.lightSurface;
  Color get surfaceLight => isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight;
  Color get surfaceBorder => isDark ? AppColors.surfaceBorder : AppColors.lightSurfaceBorder;

  // ==================== TEXT COLORS ====================
  Color get textPrimary => isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textTertiary => isDark ? AppColors.textTertiary : AppColors.lightTextTertiary;

  // ==================== ACCENT COLORS ====================
  Color get accentBlue => isDark ? AppColors.accentBlue : AppColors.lightAccentBlue;
  Color get accentPurple => isDark ? AppColors.accentPurple : AppColors.lightAccentPurple;
  Color get accentGreen => isDark ? AppColors.accentGreen : AppColors.lightAccentGreen;
  Color get accentOrange => isDark ? AppColors.accentOrange : AppColors.lightAccentOrange;
  Color get accentRed => isDark ? AppColors.accentRed : AppColors.lightAccentRed;
  Color get accentCyan => isDark ? AppColors.accentCyan : AppColors.lightAccentCyan;

  // ==================== GRADIENT ====================
  LinearGradient get accentGradient =>
      isDark ? AppColors.accentGradient : AppColors.lightAccentGradient;

  // ==================== SHADOWS ====================
  List<BoxShadow> get cardShadow =>
      isDark ? AppTheme.cardShadow : AppTheme.lightCardShadow;
  List<BoxShadow> get subtleShadow =>
      isDark ? AppTheme.subtleShadow : AppTheme.lightSubtleShadow;
  List<BoxShadow> get glowShadowBlue =>
      isDark ? AppTheme.glowShadowBlue : AppTheme.lightGlowShadowBlue;

  // ==================== REPO COLORS ====================
  Color getRepoColor(int index) =>
      isDark ? AppColors.getRepoColor(index) : AppColors.getLightRepoColor(index);
}
