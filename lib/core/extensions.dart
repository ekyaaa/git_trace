import 'package:flutter/material.dart';

extension DateTimeExtensions on DateTime {
  /// Returns true if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns the first day of this date's month (time set to midnight).
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Returns the last day of this date's month (time set to 23:59:59).
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Returns the number of days in this date's month.
  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// Returns the weekday of the first day of the month (1=Monday, 7=Sunday).
  int get firstWeekdayOfMonth => DateTime(year, month, 1).weekday;

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  /// Returns true if this date is a weekend (Saturday or Sunday).
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Returns a date-only DateTime (time set to midnight).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns the ISO date string (YYYY-MM-DD).
  String get isoDateString =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

extension StringTimeExtensions on String {
  /// Validates if the string is a valid time format (HH.MM).
  bool get isValidTimeFormat {
    final regex = RegExp(r'^\d{2}\.\d{2}$');
    if (!regex.hasMatch(this)) return false;
    final parts = split('.');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  /// Converts "HH.MM" to TimeOfDay.
  TimeOfDay? toTimeOfDay() {
    if (!isValidTimeFormat) return null;
    final parts = split('.');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

extension TimeOfDayExtensions on TimeOfDay {
  /// Converts TimeOfDay to "HH.MM" format.
  String toFormattedString() {
    return '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';
  }
}
