import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/report_row_model.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../services/excel_exporter.dart';
import '../widgets/export/report_preview_table.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  List<ReportRowModel> _previewRows = [];
  List<String> _missingDates = [];
  bool _loading = true;
  bool _exporting = false;
  String? _lastExportPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPreview);
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    final commits = ref.read(commitsProvider).valueOrNull ?? [];
    final calState = ref.read(calendarStateProvider);
    final rows = await ExcelExporter.buildReportRows(
      commits,
      calState.month,
      calState.year,
    );
    final missing = await ExcelExporter.getMissingWorkHoursDates(
      commits,
      calState.month,
      calState.year,
    );
    setState(() {
      _previewRows = rows;
      _missingDates = missing;
      _loading = false;
    });
  }

  Future<void> _export() async {
    final commits = ref.read(commitsProvider).valueOrNull ?? [];

    String? outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Simpan',
    );

    if (outputPath == null) {
      final dir = await getDownloadsDirectory();
      outputPath = dir?.path;
      if (outputPath == null) return;
    }

    setState(() => _exporting = true);
    final calState = ref.read(calendarStateProvider);

    final filePath = await ExcelExporter.exportReport(
      commits: commits,
      month: calState.month,
      year: calState.year,
      outputPath: outputPath,
    );

    setState(() {
      _exporting = false;
      _lastExportPath = filePath;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filePath != null
              ? 'Berhasil! File disimpan di:\n$filePath'
              : 'Gagal membuat file Excel.'),
          backgroundColor:
              filePath != null ? AppColors.accentGreen : AppColors.accentRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calState = ref.watch(calendarStateProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export Laporan',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    'Bulan ${calState.month}/${calState.year} • ${_previewRows.length} hari kerja',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(children: [
                if (_missingDates.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_amber,
                          size: 14, color: AppColors.accentOrange),
                      const SizedBox(width: 6),
                      Text('${_missingDates.length} hari belum diisi jam',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.accentOrange)),
                    ]),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exporting || _previewRows.isEmpty ? null : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_download, size: 16),
                  label: Text(_exporting ? 'Exporting...' : 'Export Excel'),
                ),
              ]),
            ],
          ),
        ),

        // Preview table
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentBlue, strokeWidth: 2))
              : _previewRows.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.table_chart_outlined,
                            size: 64,
                            color: AppColors.textTertiary
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('Belum ada data untuk di-export',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Muat commit terlebih dahulu dari tab Kalender',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary)),
                      ]))
                  : ReportPreviewTable(rows: _previewRows),
        ),

        // Last export path
        if (_lastExportPath != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border:
                  Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle,
                  size: 14, color: AppColors.accentGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'File terakhir: $_lastExportPath',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
