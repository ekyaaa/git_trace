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
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: 0.08)
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: color.withValues(alpha: 0.25))
                : null,
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
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

              // Color dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Repo info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.repo.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Tooltip(
                      message: widget.repo.path,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 9,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              displayPath,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${widget.repo.totalCommits} commits',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (widget.repo.lastCommitDate != null) ...[
                          const Text(
                            ' • ',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textTertiary),
                          ),
                          Text(
                            DateFormat('d MMM yyyy')
                                .format(widget.repo.lastCommitDate!),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary,
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
