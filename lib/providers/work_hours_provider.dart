import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/work_hours_storage.dart';

/// Provider for working hours of the current month.
final workHoursProvider =
    StateNotifierProvider<WorkHoursNotifier, Map<String, WorkHoursData>>((ref) {
  return WorkHoursNotifier();
});

class WorkHoursNotifier extends StateNotifier<Map<String, WorkHoursData>> {
  WorkHoursNotifier() : super({});

  /// Load all working hours for a specific month.
  Future<void> loadMonth(int year, int month) async {
    final hours = await WorkHoursStorage.getMonthWorkHours(year, month);
    state = hours;
  }

  /// Set working hours for a specific date.
  Future<void> setHours(String dateKey, String checkIn, String checkOut) async {
    await WorkHoursStorage.setWorkHours(dateKey, checkIn, checkOut);
    state = {
      ...state,
      dateKey: WorkHoursData(checkIn: checkIn, checkOut: checkOut),
    };
  }

  /// Remove working hours for a specific date.
  Future<void> removeHours(String dateKey) async {
    await WorkHoursStorage.removeWorkHours(dateKey);
    final newState = {...state};
    newState.remove(dateKey);
    state = newState;
  }

  /// Bulk set working hours for a date range.
  Future<void> bulkSetHours({
    required DateTime startDate,
    required DateTime endDate,
    required String checkIn,
    required String checkOut,
    bool weekdaysOnly = true,
  }) async {
    await WorkHoursStorage.bulkSetWorkHours(
      startDate: startDate,
      endDate: endDate,
      checkIn: checkIn,
      checkOut: checkOut,
      weekdaysOnly: weekdaysOnly,
    );

    // Reload current state
    final newState = <String, WorkHoursData>{...state};
    var current = startDate;
    while (!current.isAfter(endDate)) {
      if (!weekdaysOnly || (current.weekday >= 1 && current.weekday <= 5)) {
        final dateKey =
            '${current.year.toString().padLeft(4, '0')}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        newState[dateKey] = WorkHoursData(checkIn: checkIn, checkOut: checkOut);
      }
      current = current.add(const Duration(days: 1));
    }
    state = newState;
  }

  WorkHoursData? getHours(String dateKey) => state[dateKey];
}
