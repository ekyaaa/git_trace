import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme_colors.dart';
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
    final colors = ThemeColors.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.isCurrentMonth
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.isCurrentMonth ? () => _showDayCommitsDialog() : null,
        child: AnimatedContainer(
          duration: AppConstants.animDurationFast,
          curve: AppCurves.easeOutExpo,
          decoration: BoxDecoration(
            color: _getCellColor(isToday, _hovered, widget.isCurrentMonth, colors),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall - 2),
            border: Border.all(
              color: isToday
                  ? colors.accentBlue.withValues(alpha: 0.6)
                  : _hovered && widget.isCurrentMonth
                      ? colors.surfaceBorder.withValues(alpha: 0.8)
                      : colors.surfaceBorder.withValues(alpha: 0.2),
              width: isToday ? 2 : 0.5,
            ),
            boxShadow: _hovered && widget.isCurrentMonth
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date number + work hours indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 5, 6, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? colors.accentBlue
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
                                    ? colors.textTertiary
                                        .withValues(alpha: 0.4)
                                    : isWeekend
                                        ? colors.accentRed
                                            .withValues(alpha: 0.7)
                                        : colors.textSecondary,
                          ),
                        ),
                      ),
                      if (hasHours && widget.isCurrentMonth)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.accentGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.accentGreen.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${widget.workHours!.checkIn}-${widget.workHours!.checkOut}',
                            style: TextStyle(
                              fontSize: 7,
                              color: colors.accentGreen,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Commit count indicator (small)
                if (hasCommits && widget.isCurrentMonth && widget.commits.length > 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                    child: Text(
                      '${widget.commits.length} commits',
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.textTertiary.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Commit cards
                if (hasCommits && widget.isCurrentMonth)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: widget.commits.length > 4 ? 4 : widget.commits.length,
                      itemBuilder: (context, index) {
                        final commit = widget.commits[index];
                        final colorIndex =
                            widget.repoColorMap[commit.repoName] ?? 0;
                        return CommitCard(
                          commit: commit,
                          color: colors.getRepoColor(colorIndex),
                        );
                      },
                    ),
                  ),

                // Overflow indicator
                if (hasCommits && widget.isCurrentMonth && widget.commits.length > 4)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 3),
                    child: Text(
                      '+${widget.commits.length - 4} more',
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.textTertiary.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCellColor(bool isToday, bool hovered, bool isCurrentMonth, ThemeColors colors) {
    if (!isCurrentMonth) return colors.background.withValues(alpha: 0.3);
    if (isToday && hovered) {
      return colors.accentBlue.withValues(alpha: 0.1);
    }
    if (hovered) return colors.surfaceLight.withValues(alpha: 0.8);
    if (isToday) return colors.accentBlue.withValues(alpha: 0.06);
    return colors.background;
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
