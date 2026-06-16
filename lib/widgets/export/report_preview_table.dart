import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme_colors.dart';
import '../../models/report_row_model.dart';

class ReportPreviewTable extends StatelessWidget {
  final List<ReportRowModel> rows;
  final Function(int index, String value) onKegiatanChanged;
  final Function(int index) onResetKegiatan;

  const ReportPreviewTable({
    super.key,
    required this.rows,
    required this.onKegiatanChanged,
    required this.onResetKegiatan,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusMedium),
              ),
              border: Border.all(
                color: colors.surfaceBorder.withValues(alpha: 0.6),
              ),
              boxShadow: colors.subtleShadow,
            ),
            child: Row(children: [
              _HeaderCell(text: 'Hari, Tanggal', flex: 3),
              _HeaderCell(text: 'Jam Masuk', flex: 1),
              _HeaderCell(text: 'Jam Pulang', flex: 1),
              _HeaderCell(text: 'Kegiatan', flex: 5),
            ]),
          ),

          // Table body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.surfaceBorder.withValues(alpha: 0.6),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppConstants.radiusMedium),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppConstants.radiusMedium),
                ),
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? Colors.transparent
                            : colors.surfaceLight.withValues(alpha: 0.3),
                        border: index < rows.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: colors.surfaceBorder.withValues(alpha: 0.3),
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DataCell(text: row.dayDate, flex: 3),
                          _DataCell(text: row.checkIn, flex: 1, center: true),
                          _DataCell(text: row.checkOut, flex: 1, center: true),
                          Expanded(
                            flex: 5,
                            child: _EditableKegiatanCell(
                              row: row,
                              onChanged: (val) => onKegiatanChanged(index, val),
                              onReset: () => onResetKegiatan(index),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool center;

  const _DataCell({
    required this.text,
    required this.flex,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            height: 1.5,
            letterSpacing: 0.1,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
  }
}

class _EditableKegiatanCell extends StatefulWidget {
  final ReportRowModel row;
  final ValueChanged<String> onChanged;
  final VoidCallback onReset;

  const _EditableKegiatanCell({
    required this.row,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<_EditableKegiatanCell> createState() => _EditableKegiatanCellState();
}

class _EditableKegiatanCellState extends State<_EditableKegiatanCell> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.row.kegiatan);
  }

  @override
  void didUpdateWidget(covariant _EditableKegiatanCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.kegiatan != widget.row.kegiatan) {
      if (_controller.text != widget.row.kegiatan) {
        final cursorPosition = _controller.selection;
        _controller.text = widget.row.kegiatan;
        try {
          _controller.selection = cursorPosition;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: colors.background.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  borderSide: BorderSide(
                    color: colors.surfaceBorder.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  borderSide: BorderSide(
                    color: colors.surfaceBorder.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  borderSide: BorderSide(
                    color: colors.accentBlue.withValues(alpha: 0.8),
                  ),
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
        Tooltip(
          message: 'Reset ke default commit',
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(Icons.refresh, size: 16, color: colors.textTertiary),
              hoverColor: colors.surfaceLight,
              onPressed: widget.onReset,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
