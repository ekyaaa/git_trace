import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/theme_colors.dart';
import '../models/report_row_model.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/report_variables_provider.dart';
import '../services/excel_exporter.dart';
import '../services/docx_exporter.dart';
import '../widgets/export/report_preview_table.dart';
import '../widgets/export/report_variable_form.dart';
import '../widgets/animations/fade_in.dart';

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
  String _exportFormat = 'excel'; // 'excel' or 'word'

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
    final colors = ThemeColors.of(context);

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
              filePath != null ? colors.accentGreen : colors.accentRed,
          duration: const Duration(seconds: 6),
          action: filePath != null
              ? SnackBarAction(
                  label: '📂 Buka Folder',
                  textColor: Colors.white,
                  onPressed: () => _openFileInManager(filePath),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _exportWord() async {
    final commits = ref.read(commitsProvider).valueOrNull ?? [];
    final variables = ref.read(reportVariablesProvider);
    final colors = ThemeColors.of(context);

    if (!variables.isFilled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Isi data Nama, NIM, Prodi, dan Mitra di bagian Data Laporan terlebih dahulu.'),
            backgroundColor: colors.accentOrange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

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

    final filePath = await DocxExporter.exportReport(
      commits: commits,
      month: calState.month,
      year: calState.year,
      outputPath: outputPath,
      variables: variables,
      customTemplatePath: variables.customTemplatePath,
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
              : 'Gagal membuat file Word.'),
          backgroundColor:
              filePath != null ? colors.accentGreen : colors.accentRed,
          duration: const Duration(seconds: 6),
          action: filePath != null
              ? SnackBarAction(
                  label: '📂 Buka Folder',
                  textColor: Colors.white,
                  onPressed: () => _openFileInManager(filePath),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _pickCustomTemplate() async {
    final colors = ThemeColors.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      dialogTitle: 'Pilih Template Word (.docx)',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ref.read(reportVariablesProvider.notifier).setCustomTemplatePath(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template custom dipilih: ${result.files.single.name}'),
            backgroundColor: colors.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openFileInManager(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,"$filePath"']);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        final dir = file.parent.path;
        await Process.run('xdg-open', [dir]);
      }
    } catch (e) {
      debugPrint('Gagal membuka file manager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final calState = ref.watch(calendarStateProvider);
    final colors = ThemeColors.of(context);

    return Column(
      children: [
        // Header
        FadeIn(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingXXLarge),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(
                  color: colors.surfaceBorder.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            border: Border.all(
                              color: colors.accentBlue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            color: colors.accentBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Export Laporan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bulan ${calState.month}/${calState.year} • ${_previewRows.length} hari kerja',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                Row(children: [
                  if (_missingDates.isNotEmpty)
                    FadeIn(
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          border: Border.all(
                            color: colors.accentOrange.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.warning_amber,
                              size: 14, color: colors.accentOrange.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Text('${_missingDates.length} hari belum diisi jam',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.accentOrange.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  const SizedBox(width: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 150),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(
                          color: colors.surfaceBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFormatButton('excel', 'Excel', Icons.table_chart),
                          _buildFormatButton('word', 'Word', Icons.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed: _exporting || _previewRows.isEmpty
                          ? null
                          : (_exportFormat == 'excel' ? _export : _exportWord),
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _exportFormat == 'excel'
                                  ? Icons.file_download
                                  : Icons.file_download,
                              size: 18),
                      label: Text(_exporting
                          ? 'Exporting...'
                          : (_exportFormat == 'excel'
                              ? 'Export Excel'
                              : 'Export Word')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Content area (Word options + Preview table)
        Expanded(
          child: Column(
            children: [
              // Word export options (with constrained height + scrollable)
              if (_exportFormat == 'word')
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const ReportVariableForm(),
                        FadeIn(
                          delay: const Duration(milliseconds: 250),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingXXLarge,
                              vertical: AppConstants.spacingSmall,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickCustomTemplate,
                                    icon: const Icon(Icons.folder_open, size: 16),
                                    label: const Text('Pilih Template Custom'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: BorderSide(
                                        color: colors.surfaceBorder.withValues(alpha: 0.5),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                      ),
                                    ),
                                  ),
                                ),
                                if (ref.watch(reportVariablesProvider).customTemplatePath != null) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      ref.read(reportVariablesProvider.notifier).clearCustomTemplate();
                                    },
                                    icon: const Icon(Icons.clear, size: 16),
                                    tooltip: 'Hapus template custom',
                                    color: colors.accentRed,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Preview table (fills remaining space)
              Expanded(
                child: _loading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: colors.accentBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _previewRows.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeIn(
                                    child: Icon(
                                      Icons.table_chart_outlined,
                                      size: 64,
                                      color: colors.textTertiary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FadeIn(
                                    delay: const Duration(milliseconds: 100),
                                    child: Text(
                                      'Belum ada data untuk di-export',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FadeIn(
                                    delay: const Duration(milliseconds: 150),
                                    child: Text(
                                      'Muat commit terlebih dahulu dari tab Kalender',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ReportPreviewTable(rows: _previewRows),
              ),
            ],
          ),
        ),

        // Last export path
        if (_lastExportPath != null)
          FadeIn(
            slideOffset: const Offset(0, 10),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingMedium),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(
                    color: colors.surfaceBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.accentGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 14,
                    color: colors.accentGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File terakhir: $_lastExportPath',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary.withValues(alpha: 0.8),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildFormatButton(String format, String label, IconData icon) {
    final isSelected = _exportFormat == format;
    final colors = ThemeColors.of(context);

    return InkWell(
      onTap: () => setState(() => _exportFormat = format),
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.accentBlue : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.accentBlue : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
