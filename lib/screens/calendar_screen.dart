import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/commit_model.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/work_hours_provider.dart';
import '../widgets/calendar/month_calendar.dart';
import '../widgets/calendar/month_navigator.dart';
import '../widgets/work_hours/bulk_hour_dialog.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MonthNavigator(
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
            Row(children: [
              _chip(Icons.schedule, 'Atur Jam Kerja', _showBulkHoursDialog),
              const SizedBox(width: 8),
              _chip(Icons.refresh, 'Refresh', () {
                ref.read(commitsProvider.notifier).loadCommits();
              }),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          _stat(Icons.commit, '$totalCommits', 'Commit', AppColors.accentBlue),
          const SizedBox(width: 16),
          _stat(Icons.calendar_today, '$activeDays', 'Hari Aktif',
              AppColors.accentGreen),
          const SizedBox(width: 16),
          _stat(Icons.source, '$repoCount', 'Repo', AppColors.accentPurple),
          const SizedBox(width: 16),
          _stat(Icons.access_time, '${workHours.length}', 'Jam Diisi',
              AppColors.accentOrange),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
      ]),
    ]);
  }

  Widget _buildCalendar(AsyncValue<List<CommitModel>> commits,
      CalendarState calState, Map<DateTime, List<CommitModel>> commitsByDate,
      Map workHours) {
    return commits.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2),
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
