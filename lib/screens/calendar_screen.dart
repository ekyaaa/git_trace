import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/theme_colors.dart';
import '../models/commit_model.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/work_hours_provider.dart';
import '../widgets/calendar/month_calendar.dart';
import '../widgets/calendar/month_navigator.dart';
import '../widgets/work_hours/bulk_hour_dialog.dart';
import '../widgets/animations/fade_in.dart';
import '../widgets/animations/scale_on_hover.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final calState = ref.watch(calendarStateProvider);
    final commits = ref.watch(commitsProvider);
    final workHours = ref.watch(workHoursProvider);

    final commitsByDate = <DateTime, List<CommitModel>>{};
    commits.whenData((list) {
      for (final c in list) {
        commitsByDate.putIfAbsent(c.dateOnly, () => []).add(c);
      }
    });

    final totalCommits = commits.valueOrNull?.length ?? 0;
    final activeDays = commitsByDate.length;
    final repoCount =
        commits.valueOrNull?.map((c) => c.repoName).toSet().length ?? 0;

    return Column(
      children: [
        _buildTopBar(calState, totalCommits, activeDays, repoCount, workHours),
        Expanded(child: _buildCalendar(commits, calState, commitsByDate, workHours)),
      ],
    );
  }

  Widget _buildTopBar(CalendarState calState, int totalCommits, int activeDays,
      int repoCount, Map workHours) {
    final colors = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppConstants.spacingXXLarge, AppConstants.spacingLarge, AppConstants.spacingXXLarge, AppConstants.spacingMedium),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FadeIn(
              child: MonthNavigator(
                month: calState.month,
                year: calState.year,
                onPrevious: () {
                  ref.read(calendarStateProvider.notifier).previousMonth();
                  _reloadData();
                },
                onNext: () {
                  ref.read(calendarStateProvider.notifier).nextMonth();
                  _reloadData();
                },
              ),
            ),
            Row(children: [
              FadeIn(
                delay: const Duration(milliseconds: 50),
                child: _chip(Icons.schedule, 'Atur Jam Kerja', _showBulkHoursDialog),
              ),
              const SizedBox(width: 8),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: _chip(Icons.refresh, 'Refresh', () {
                  ref.read(commitsProvider.notifier).loadCommits();
                }),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          _stat(Icons.commit, '$totalCommits', 'Commit', colors.accentBlue),
          const SizedBox(width: 20),
          _stat(Icons.calendar_today, '$activeDays', 'Hari Aktif',
              colors.accentGreen),
          const SizedBox(width: 20),
          _stat(Icons.source, '$repoCount', 'Repo', colors.accentPurple),
          const SizedBox(width: 20),
          _stat(Icons.access_time, '${workHours.length}', 'Jam Diisi',
              colors.accentOrange),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap) {
    final colors = ThemeColors.of(context);

    return ScaleOnHover(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceBorder.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(
            color: colors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              )),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    final colors = ThemeColors.of(context);

    return FadeIn(
      delay: const Duration(milliseconds: 60),
      slideOffset: const Offset(0, 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall - 2),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                letterSpacing: -0.2,
              )),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: colors.textTertiary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              )),
        ]),
      ]),
    );
  }

  Widget _buildCalendar(AsyncValue<List<CommitModel>> commits,
      CalendarState calState, Map<DateTime, List<CommitModel>> commitsByDate,
      Map workHours) {
    final colors = ThemeColors.of(context);

    return commits.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.accentBlue, strokeWidth: 2),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (_) => MonthCalendar(
        month: calState.month,
        year: calState.year,
        commitsByDate: commitsByDate,
        workHours: workHours.cast<String, dynamic>(),
        emptyMessage: commitsByDate.isEmpty
            ? 'Pilih repository dan klik "Muat Commit"'
            : null,
      ),
    );
  }

  void _reloadData() {
    final s = ref.read(calendarStateProvider);
    ref.read(workHoursProvider.notifier).loadMonth(s.year, s.month);
    ref.read(commitsProvider.notifier).loadCommits();
  }

  void _showBulkHoursDialog() {
    final s = ref.read(calendarStateProvider);
    showDialog(
      context: context,
      builder: (_) => BulkHourDialog(
        month: s.month,
        year: s.year,
        onSave: (checkIn, checkOut, weekdaysOnly) async {
          final start = DateTime(s.year, s.month, 1);
          final end = DateTime(s.year, s.month + 1, 0);
          await ref.read(workHoursProvider.notifier).bulkSetHours(
                startDate: start,
                endDate: end,
                checkIn: checkIn,
                checkOut: checkOut,
                weekdaysOnly: weekdaysOnly,
              );
        },
      ),
    );
  }
}
