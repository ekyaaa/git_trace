import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'GitTrace';
  static const String appTagline = 'Trace every commit, report every day.';
  static const String appVersion = '1.0.0';

  // Default working hours
  static const String defaultCheckIn = '08.00';
  static const String defaultCheckOut = '17.00';

  // Date format patterns
  static const String dateFormatIndonesian = 'EEEE, d MMM yyyy';
  static const String dateFormatShort = 'd MMM yyyy';
  static const String dateFormatKey = 'yyyy-MM-dd';
  static const String timeFormat = 'HH.mm';

  // SharedPreferences keys
  static const String prefKeyWorkHours = 'work_hours_';
  static const String prefKeyRootFolder = 'root_folder';
  static const String prefKeySelectedRepos = 'selected_repos';
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyMergeDuplicates = 'merge_duplicates';
  static const String prefKeyExportPath = 'export_path';

  // Git commands
  static const String gitExecutable = 'git';

  // Calendar
  static const int calendarColumns = 7;
  static const int calendarRows = 6;
  static const List<String> dayHeaders = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> dayHeadersFull = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  // Window
  static const double minWindowWidth = 1100.0;
  static const double minWindowHeight = 700.0;
  static const double defaultWindowWidth = 1400.0;
  static const double defaultWindowHeight = 850.0;

  // Sidebar
  static const double sidebarWidth = 320.0;

  // Animation durations
  static const Duration animDurationFast = Duration(milliseconds: 200);
  static const Duration animDurationNormal = Duration(milliseconds: 300);
  static const Duration animDurationSlow = Duration(milliseconds: 400);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 24.0;
}

/// Easing curves for smooth animations
class AppCurves {
  AppCurves._();

  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInOutCubic = Cubic(0.65, 0, 0.35, 1);
  static const Curve easeOutBack = Cubic(0.34, 1.56, 0.64, 1);
}

class AppColors {
  AppColors._();

  // ==================== DARK THEME PALETTE ====================
  // Background
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color surfaceBorder = Color(0xFF30363D);
  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // ==================== LIGHT THEME PALETTE ====================
  // Background
  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF3F4F6);
  static const Color lightSurfaceBorder = Color(0xFFD0D7DE);
  // Text
  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF656D76);
  static const Color lightTextTertiary = Color(0xFF8B949E);

  // ==================== ACCENT COLORS (shared) ====================
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentPurple = Color(0xFFBC8CFF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentOrange = Color(0xFFD29922);
  static const Color accentRed = Color(0xFFF85149);
  static const Color accentCyan = Color(0xFF39D2C0);

  // ==================== LIGHT ACCENT COLORS ====================
  static const Color lightAccentBlue = Color(0xFF0969DA);
  static const Color lightAccentPurple = Color(0xFF8250DF);
  static const Color lightAccentGreen = Color(0xFF1A7F37);
  static const Color lightAccentOrange = Color(0xFF9A6700);
  static const Color lightAccentRed = Color(0xFFCF222E);
  static const Color lightAccentCyan = Color(0xFF0E7C7B);

  // Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light gradient
  static const LinearGradient lightAccentGradient = LinearGradient(
    colors: [lightAccentBlue, lightAccentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Repository color palette (for commit cards)
  static const List<Color> repoColors = [
    accentBlue,
    accentPurple,
    accentGreen,
    accentOrange,
    accentCyan,
    Color(0xFFFF7B72),
    Color(0xFFF778BA),
    Color(0xFFF0883E),
    Color(0xFF79C0FF),
    Color(0xFFD2A8FF),
  ];

  // Light repository color palette
  static const List<Color> lightRepoColors = [
    lightAccentBlue,
    lightAccentPurple,
    lightAccentGreen,
    lightAccentOrange,
    lightAccentCyan,
    Color(0xFFCF222E),
    Color(0xFFBF3989),
    Color(0xFFBC4C00),
    Color(0xFF0550AE),
    Color(0xFF8250DF),
  ];

  static Color getRepoColor(int index) {
    return repoColors[index % repoColors.length];
  }

  static Color getLightRepoColor(int index) {
    return lightRepoColors[index % lightRepoColors.length];
  }
}
