import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../core/constants.dart';
import '../../models/repository_model.dart';
import '../../providers/folder_provider.dart';
import 'package:intl/intl.dart';

class RepoListTile extends ConsumerStatefulWidget {
  final RepositoryModel repo;
  final bool isSelected;
  final int colorIndex;
  final VoidCallback onToggle;

  const RepoListTile({
    super.key,
    required this.repo,
    required this.isSelected,
    required this.colorIndex,
    required this.onToggle,
  });

  @override
  ConsumerState<RepoListTile> createState() => _RepoListTileState();
}

class _RepoListTileState extends ConsumerState<RepoListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRepoColor(widget.colorIndex);
    final folder = ref.watch(folderProvider);
    String displayPath = widget.repo.path;
    if (folder != null) {
      try {
        displayPath = p.relative(widget.repo.path, from: folder);
      } catch (_) {
        // Fallback if not under the folder
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: AppConstants.animDurationFast,
          curve: AppCurves.easeOutExpo,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: 0.08)
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.6)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            border: widget.isSelected
                ? Border.all(color: color.withValues(alpha: 0.3))
                : _hovered
                    ? Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.6))
                    : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: AppConstants.animDurationFast,
                curve: AppCurves.easeOutExpo,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? color
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: widget.isSelected
                        ? color
                        : AppColors.surfaceBorder,
                    width: 1.5,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),

              // Color dot + avatar
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.repo.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Repo info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.repo.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Tooltip(
                      message: widget.repo.path,
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 9,
                            color: AppColors.textTertiary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              displayPath,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary.withValues(alpha: 0.7),
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.source_outlined,
                          size: 8,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.repo.totalCommits} commits',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textTertiary.withValues(alpha: 0.5),
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (widget.repo.lastCommitDate != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy')
                                .format(widget.repo.lastCommitDate!),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary.withValues(alpha: 0.5),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
