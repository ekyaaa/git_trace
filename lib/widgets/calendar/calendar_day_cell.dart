import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../models/commit_model.dart';
import '../../services/work_hours_storage.dart';
import 'commit_card.dart';
import 'day_commits_dialog.dart';

class CalendarDayCell extends ConsumerStatefulWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final List<CommitModel> commits;
  final WorkHoursData? workHours;
  final Map<String, int> repoColorMap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.commits,
    this.workHours,
    required this.repoColorMap,
  });

  @override
  ConsumerState<CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends ConsumerState<CalendarDayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isToday = widget.date.isToday;
    final isWeekend = widget.date.isWeekend;
    final hasCommits = widget.commits.isNotEmpty;
    final hasHours = widget.workHours != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isCurrentMonth ? () => _showDayCommitsDialog() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _getCellColor(isToday, _hovered, widget.isCurrentMonth),
            border: Border.all(
              color: isToday
                  ? AppColors.accentBlue.withValues(alpha: 0.5)
                  : AppColors.surfaceBorder.withValues(alpha: 0.5),
              width: isToday ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date number + work hours indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.accentBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.date.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? Colors.white
                              : !widget.isCurrentMonth
                                  ? AppColors.textTertiary
                                      .withValues(alpha: 0.4)
                                  : isWeekend
                                      ? AppColors.accentRed
                                          .withValues(alpha: 0.7)
                                      : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (hasHours && widget.isCurrentMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.workHours!.checkIn}-${widget.workHours!.checkOut}',
                          style: const TextStyle(
                            fontSize: 7,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Commit cards
              if (hasCommits && widget.isCurrentMonth)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: widget.commits.length,
                    itemBuilder: (context, index) {
                      final commit = widget.commits[index];
                      final colorIndex =
                          widget.repoColorMap[commit.repoName] ?? 0;
                      return CommitCard(
                        commit: commit,
                        color: AppColors.getRepoColor(colorIndex),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCellColor(bool isToday, bool hovered, bool isCurrentMonth) {
    if (!isCurrentMonth) return AppColors.background.withValues(alpha: 0.5);
    if (isToday && hovered) {
      return AppColors.accentBlue.withValues(alpha: 0.08);
    }
    if (hovered) return AppColors.surfaceLight.withValues(alpha: 0.7);
    if (isToday) return AppColors.accentBlue.withValues(alpha: 0.05);
    return AppColors.background;
  }

  void _showDayCommitsDialog() {
    showDialog(
      context: context,
      builder: (_) => DayCommitsDialog(
        date: widget.date,
        commits: widget.commits,
        repoColorMap: widget.repoColorMap,
      ),
    );
  }
}
