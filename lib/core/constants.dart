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
}

class AppColors {
  AppColors._();

  // Dark theme palette
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color surfaceBorder = Color(0xFF30363D);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // Accent colors
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentPurple = Color(0xFFBC8CFF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentOrange = Color(0xFFD29922);
  static const Color accentRed = Color(0xFFF85149);
  static const Color accentCyan = Color(0xFF39D2C0);

  // Gradient
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, accentPurple],
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

  static Color getRepoColor(int index) {
    return repoColors[index % repoColors.length];
  }
}
