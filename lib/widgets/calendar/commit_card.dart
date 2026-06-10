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
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message:
            '[${widget.commit.repoName}] ${widget.commit.subject}\n${widget.commit.timeString} — ${widget.commit.authorName}',
        waitDuration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: AppConstants.animDurationFast,
          curve: AppCurves.easeOutExpo,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.18)
                : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: widget.color,
                width: 2.5,
              ),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(
                widget.commit.timeString,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: widget.color.withValues(alpha: 0.9),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.commit.subject,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 1.2,
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
