import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/commit_model.dart';
import '../../services/work_hours_storage.dart';
import 'calendar_day_cell.dart';

class MonthCalendar extends StatelessWidget {
  final int month;
  final int year;
  final Map<DateTime, List<CommitModel>> commitsByDate;
  final Map<String, dynamic> workHours;
  final String? emptyMessage;

  const MonthCalendar({
    super.key,
    required this.month,
    required this.year,
    required this.commitsByDate,
    required this.workHours,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Build repo color map
    final repoColorMap = <String, int>{};
    int colorIdx = 0;
    for (final commits in commitsByDate.values) {
      for (final c in commits) {
        if (!repoColorMap.containsKey(c.repoName)) {
          repoColorMap[c.repoName] = colorIdx++;
        }
      }
    }

    // Calculate calendar grid
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday=1, Sunday=7. We want Monday as column 0.
    final startWeekday = firstDay.weekday; // 1=Mon ... 7=Sun

    return Column(
      children: [
        // Day headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: AppConstants.dayHeaders.map((day) {
              final isWeekend = day == 'Sab' || day == 'Min';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWeekend
                          ? AppColors.accentRed.withValues(alpha: 0.6)
                          : AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid
        Expanded(
          child: _buildGrid(
              firstDay, daysInMonth, startWeekday, repoColorMap),
        ),

        // Legend
        if (repoColorMap.isNotEmpty) _buildLegend(repoColorMap),
      ],
    );
  }

  Widget _buildGrid(DateTime firstDay, int daysInMonth, int startWeekday,
      Map<String, int> repoColorMap) {
    // We need 6 rows max
    final totalCells = 42; // 7 * 6
    final cells = <Widget>[];

    for (int i = 0; i < totalCells; i++) {
      final dayOffset = i - (startWeekday - 1);
      final dayNum = dayOffset + 1;

      DateTime cellDate;
      bool isCurrentMonth;

      if (dayNum < 1) {
        // Previous month
        final prevMonth = month == 1 ? 12 : month - 1;
        final prevYear = month == 1 ? year - 1 : year;
        final prevDays = DateTime(prevYear, prevMonth + 1, 0).day;
        cellDate = DateTime(prevYear, prevMonth, prevDays + dayNum);
        isCurrentMonth = false;
      } else if (dayNum > daysInMonth) {
        // Next month
        final nextMonth = month == 12 ? 1 : month + 1;
        final nextYear = month == 12 ? year + 1 : year;
        cellDate = DateTime(nextYear, nextMonth, dayNum - daysInMonth);
        isCurrentMonth = false;
      } else {
        cellDate = DateTime(year, month, dayNum);
        isCurrentMonth = true;
      }

      final dateKey = DateTime(cellDate.year, cellDate.month, cellDate.day);
      final commits = commitsByDate[dateKey] ?? [];

      // Get work hours
      final whKey =
          '${cellDate.year.toString().padLeft(4, '0')}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
      final wh = workHours[whKey];
      WorkHoursData? workHoursData;
      if (wh is WorkHoursData) {
        workHoursData = wh;
      }

      cells.add(
        CalendarDayCell(
          date: cellDate,
          isCurrentMonth: isCurrentMonth,
          commits: commits,
          workHours: workHoursData,
          repoColorMap: repoColorMap,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
      childAspectRatio: 1.35,
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  Widget _buildLegend(Map<String, int> repoColorMap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: repoColorMap.entries.map((entry) {
            final color = AppColors.getRepoColor(entry.value);
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
