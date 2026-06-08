import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/report_row_model.dart';

class ReportPreviewTable extends StatelessWidget {
  final List<ReportRowModel> rows;

  const ReportPreviewTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Row(children: [
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
                border: Border.all(color: AppColors.surfaceBorder),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10)),
              ),
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.surfaceBorder),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Container(
                    color: index.isEven
                        ? Colors.transparent
                        : AppColors.surfaceLight.withValues(alpha: 0.3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DataCell(text: row.dayDate, flex: 3),
                        _DataCell(text: row.checkIn, flex: 1, center: true),
                        _DataCell(text: row.checkOut, flex: 1, center: true),
                        _DataCell(text: row.kegiatan, flex: 5),
                      ],
                    ),
                  );
                },
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
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
  }
}
