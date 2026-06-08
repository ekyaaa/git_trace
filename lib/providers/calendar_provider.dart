import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commit_model.dart';

/// State for the calendar view (current month/year).
class CalendarState {
  final int month;
  final int year;

  const CalendarState({required this.month, required this.year});

  CalendarState copyWith({int? month, int? year}) {
    return CalendarState(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  String toString() => 'CalendarState(month: $month, year: $year)';
}

/// Provider for the current calendar month/year state.
final calendarStateProvider =
    StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
  final now = DateTime.now();
  return CalendarStateNotifier(CalendarState(month: now.month, year: now.year));
});

class CalendarStateNotifier extends StateNotifier<CalendarState> {
  CalendarStateNotifier(super.state);

  void nextMonth() {
    if (state.month == 12) {
      state = CalendarState(month: 1, year: state.year + 1);
    } else {
      state = CalendarState(month: state.month + 1, year: state.year);
    }
  }

  void previousMonth() {
    if (state.month == 1) {
      state = CalendarState(month: 12, year: state.year - 1);
    } else {
      state = CalendarState(month: state.month - 1, year: state.year);
    }
  }

  void setMonthYear(int month, int year) {
    state = CalendarState(month: month, year: year);
  }
}

/// Provider that groups commits by date for the calendar view.
final calendarCommitsProvider =
    Provider<Map<DateTime, List<CommitModel>>>((ref) {
  return {};
});
