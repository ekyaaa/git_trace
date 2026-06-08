import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/commit_model.dart';

class CommitCard extends StatefulWidget {
  final CommitModel commit;
  final Color color;

  const CommitCard({
    super.key,
    required this.commit,
    required this.color,
  });

  @override
  State<CommitCard> createState() => _CommitCardState();
}

class _CommitCardState extends State<CommitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message:
            '[${widget.commit.repoName}] ${widget.commit.subject}\n${widget.commit.timeString} — ${widget.commit.authorName}',
        waitDuration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.2)
                : widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: widget.color,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.commit.timeString,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.commit.subject,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
