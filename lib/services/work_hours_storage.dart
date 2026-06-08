import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class WorkHoursData {
  final String checkIn;
  final String checkOut;

  const WorkHoursData({
    required this.checkIn,
    required this.checkOut,
  });

  @override
  String toString() => '$checkIn|$checkOut';
}

class WorkHoursStorage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Gets stored working hours for a specific date (ISO format YYYY-MM-DD).
  static Future<WorkHoursData?> getWorkHours(String dateKey) async {
    final prefs = await _instance;
    final key = '${AppConstants.prefKeyWorkHours}$dateKey';
    final value = prefs.getString(key);

    if (value == null || !value.contains('|')) return null;

    final parts = value.split('|');
    return WorkHoursData(
      checkIn: parts[0],
      checkOut: parts[1],
    );
  }

  /// Saves working hours for a specific date.
  static Future<void> setWorkHours(
    String dateKey,
    String checkIn,
    String checkOut,
  ) async {
    final prefs = await _instance;
    final key = '${AppConstants.prefKeyWorkHours}$dateKey';
    await prefs.setString(key, '$checkIn|$checkOut');
  }

  /// Removes working hours for a specific date.
  static Future<void> removeWorkHours(String dateKey) async {
    final prefs = await _instance;
    final key = '${AppConstants.prefKeyWorkHours}$dateKey';
    await prefs.remove(key);
  }

  /// Gets all working hours for a given month (1-indexed).
  static Future<Map<String, WorkHoursData>> getMonthWorkHours(
    int year,
    int month,
  ) async {
    final prefs = await _instance;
    final result = <String, WorkHoursData>{};

    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final key = '${AppConstants.prefKeyWorkHours}$dateKey';
      final value = prefs.getString(key);

      if (value != null && value.contains('|')) {
        final parts = value.split('|');
        result[dateKey] = WorkHoursData(
          checkIn: parts[0],
          checkOut: parts[1],
        );
      }
    }

    return result;
  }

  /// Bulk set working hours for a range of dates.
  static Future<void> bulkSetWorkHours({
    required DateTime startDate,
    required DateTime endDate,
    required String checkIn,
    required String checkOut,
    bool weekdaysOnly = true,
  }) async {
    var current = startDate;
    while (!current.isAfter(endDate)) {
      if (!weekdaysOnly || (current.weekday >= 1 && current.weekday <= 5)) {
        final dateKey =
            '${current.year.toString().padLeft(4, '0')}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        await setWorkHours(dateKey, checkIn, checkOut);
      }
      current = current.add(const Duration(days: 1));
    }
  }

  /// Saves the root folder path.
  static Future<void> saveRootFolder(String path) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.prefKeyRootFolder, path);
  }

  /// Gets the saved root folder path.
  static Future<String?> getRootFolder() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.prefKeyRootFolder);
  }
}
