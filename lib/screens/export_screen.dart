import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme_colors.dart';
import '../models/report_row_model.dart';
import '../models/commit_model.dart';
import '../providers/commits_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/report_variables_provider.dart';
import '../services/excel_exporter.dart';
import '../services/docx_exporter.dart';
import '../widgets/export/report_preview_table.dart';
import '../widgets/export/report_variable_form.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../services/draft_kegiatan_storage.dart';
import '../services/pdf_exporter.dart';
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
  String _exportFormat = 'excel'; // 'excel' or 'docs'
  bool _mergeDuplicates = true;
  Timer? _draftSaveDebounce;
  final Map<String, String> _pendingDrafts = {};

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    if (_pendingDrafts.isNotEmpty) {
      _pendingDrafts.forEach((key, value) {
        DraftKegiatanStorage.setDraftKegiatan(key, value);
      });
    }
    super.dispose();
  }

  void _onKegiatanChanged(int index, String newText) {
    final row = _previewRows[index];
    setState(() {
      _previewRows[index] = ReportRowModel(
        dateKey: row.dateKey,
        dayDate: row.dayDate,
        checkIn: row.checkIn,
        checkOut: row.checkOut,
        kegiatan: newText,
      );
    });

    _pendingDrafts[row.dateKey] = newText;

    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final draftsCopy = Map<String, String>.from(_pendingDrafts);
      _pendingDrafts.clear();
      for (final entry in draftsCopy.entries) {
        await DraftKegiatanStorage.setDraftKegiatan(entry.key, entry.value);
      }
    });
  }

  Future<void> _onResetKegiatan(int index) async {
    final row = _previewRows[index];
    await DraftKegiatanStorage.removeDraftKegiatan(row.dateKey);
    _pendingDrafts.remove(row.dateKey);
    await _loadPreview();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMergePreference();
      await _loadPreview();
    });
  }

  Future<void> _loadMergePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(AppConstants.prefKeyMergeDuplicates);
    if (stored != null) {
      setState(() => _mergeDuplicates = stored);
    }
  }

  Future<void> _saveMergePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyMergeDuplicates, value);
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    final commits = ref.read(commitsProvider).valueOrNull ?? [];
    final calState = ref.read(calendarStateProvider);
    final rows = await ExcelExporter.buildReportRows(
      commits,
      calState.month,
      calState.year,
      mergeDuplicates: _mergeDuplicates,
    );
    final missing = await ExcelExporter.getEmptyActivityDates(
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

    final prefs = await SharedPreferences.getInstance();
    final initialDir = prefs.getString(AppConstants.prefKeyExportPath);

    String? outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Simpan',
      initialDirectory: initialDir,
    );

    if (outputPath == null) {
      final dir = await getDownloadsDirectory();
      outputPath = dir?.path;
      if (outputPath == null) return;
    } else {
      await prefs.setString(AppConstants.prefKeyExportPath, outputPath);
    }

    setState(() => _exporting = true);
    final calState = ref.read(calendarStateProvider);

    final filePath = await ExcelExporter.exportReport(
      commits: commits,
      month: calState.month,
      year: calState.year,
      outputPath: outputPath,
      mergeDuplicates: _mergeDuplicates,
    );

    setState(() {
      _exporting = false;
      _lastExportPath = filePath;
    });

    if (mounted) {
      if (filePath != null) {
        _showExportSuccessDialog(filePath, 'Excel');
      } else {
        _showExportFailureDialog('Terjadi kesalahan yang tidak diketahui.', 'Excel');
      }
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

    final effectiveNamaMahasiswa = variables.namaMahasiswa.isNotEmpty ? variables.namaMahasiswa : variables.nama;
    final effectiveNamaPembimbing = variables.namaPembimbing.isNotEmpty ? variables.namaPembimbing : variables.nama;
    final effectiveNamaPembimbingLapangan = variables.namaPembimbingLapangan.isNotEmpty ? variables.namaPembimbingLapangan : variables.nama;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Data Export'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Laporan:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text('Nama: ${variables.nama}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('NIM: ${variables.nim}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('Prodi: ${variables.prodi}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('Mitra: ${variables.mitra}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Text('Tanda Tangan:', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text('Nama Mahasiswa: $effectiveNamaMahasiswa', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('Dosen Pembimbing: $effectiveNamaPembimbing', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('Pembimbing Lapangan: $effectiveNamaPembimbingLapangan', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              if (variables.namaMahasiswa.isEmpty || variables.namaPembimbing.isEmpty || variables.namaPembimbingLapangan.isEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: colors.accentOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nama TTD kosong, otomatis menggunakan nama "${variables.nama}"',
                          style: TextStyle(fontSize: 11, color: colors.accentOrange),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(reportVariablesProvider.notifier).saveImmediate();

    final prefs = await SharedPreferences.getInstance();
    final initialDir = prefs.getString(AppConstants.prefKeyExportPath);

    String? outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Simpan',
      initialDirectory: initialDir,
    );

    if (outputPath == null) {
      final dir = await getDownloadsDirectory();
      outputPath = dir?.path;
      if (outputPath == null) return;
    } else {
      await prefs.setString(AppConstants.prefKeyExportPath, outputPath);
    }

    setState(() => _exporting = true);
    final calState = ref.read(calendarStateProvider);

    final effectiveVariables = variables.copyWith(
      namaMahasiswa: effectiveNamaMahasiswa,
      namaPembimbing: effectiveNamaPembimbing,
      namaPembimbingLapangan: effectiveNamaPembimbingLapangan,
    );

    String? filePath;
    String? errorMsg;
    try {
      filePath = await DocxExporter.exportReport(
        commits: commits,
        month: calState.month,
        year: calState.year,
        outputPath: outputPath,
        variables: effectiveVariables,
        customTemplatePath: variables.customTemplatePath,
        mergeDuplicates: _mergeDuplicates,
      );
    } catch (e) {
      errorMsg = e.toString();
    }

    setState(() {
      _exporting = false;
      _lastExportPath = filePath;
    });

    if (mounted) {
      if (filePath != null) {
        _showExportSuccessDialog(filePath, 'Word');
      } else {
        _showExportFailureDialog(errorMsg ?? 'Terjadi kesalahan yang tidak diketahui.', 'Word');
      }
    }
  }

  Future<void> _exportDocs() async {
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

    final selectedFormat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.6)),
        ),
        title: Text(
          'Pilih Format Dokumen',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogFormatCard(
              title: 'Word Document (.docx)',
              subtitle: 'Ekspor logbook ke format Word (.docx) menggunakan template.',
              icon: Icons.file_present,
              iconColor: colors.accentBlue,
              onTap: () => Navigator.of(ctx).pop('word'),
            ),
            const SizedBox(height: 12),
            _buildDialogFormatCard(
              title: 'PDF Document (.pdf)',
              subtitle: 'Ekspor logbook ke format PDF (.pdf) secara langsung.',
              icon: Icons.picture_as_pdf,
              iconColor: colors.accentRed,
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
        ],
      ),
    );

    if (selectedFormat == 'word') {
      await _exportWord();
    } else if (selectedFormat == 'pdf') {
      await _exportPdf();
    }
  }

  Widget _buildDialogFormatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final colors = ThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: colors.surfaceBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final commits = ref.read(commitsProvider).valueOrNull ?? [];
    final variables = ref.read(reportVariablesProvider);

    final prefs = await SharedPreferences.getInstance();
    final initialDir = prefs.getString(AppConstants.prefKeyExportPath);

    String? outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Simpan PDF',
      initialDirectory: initialDir,
    );

    if (outputPath == null) {
      final dir = await getDownloadsDirectory();
      outputPath = dir?.path;
      if (outputPath == null) return;
    } else {
      await prefs.setString(AppConstants.prefKeyExportPath, outputPath);
    }

    setState(() => _exporting = true);
    final calState = ref.read(calendarStateProvider);

    final filePath = await PdfExporter.exportReport(
      commits: commits,
      month: calState.month,
      year: calState.year,
      outputPath: outputPath,
      variables: variables,
      customTemplatePath: variables.customTemplatePath,
      mergeDuplicates: _mergeDuplicates,
    );

    setState(() {
      _exporting = false;
      _lastExportPath = filePath;
    });

    if (mounted) {
      if (filePath != null) {
        _showExportSuccessDialog(filePath, 'PDF');
      } else {
        _showExportFailureDialog('Terjadi kesalahan yang tidak diketahui saat mengekspor PDF.', 'PDF');
      }
    }
  }

  Future<void> _downloadDefaultTemplate() async {
    final colors = ThemeColors.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final initialDir = prefs.getString(AppConstants.prefKeyExportPath);

      String? outputPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Folder Simpan Template',
        initialDirectory: initialDir,
      );

      if (outputPath == null) {
        final dir = await getDownloadsDirectory();
        outputPath = dir?.path;
        if (outputPath == null) return;
      } else {
        await prefs.setString(AppConstants.prefKeyExportPath, outputPath);
      }

      final byteData = await rootBundle.load(
        'assets/templates/default_logbook_template.docx',
      );
      final bytes = byteData.buffer.asUint8List();

      final filePath = p.join(outputPath, 'default_logbook_template.docx');
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template berhasil diunduh ke: $filePath'),
            backgroundColor: colors.accentGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh template: $e'),
            backgroundColor: colors.accentRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  void _showExportSuccessDialog(String filePath, String formatName) {
    final colors = ThemeColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.accentGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              'Export Selesai',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan $formatName berhasil diexport.',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: colors.surfaceBorder.withValues(alpha: 0.4)),
              ),
              child: SelectableText(
                filePath,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Tutup',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openFileInManager(filePath);
            },
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Buka Folder'),
          ),
        ],
      ),
    );
  }

  void _showExportFailureDialog(String errorMsg, String formatName) {
    final colors = ThemeColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: colors.accentRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Export Gagal',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Gagal melakukan export $formatName.\n\nDetail: $errorMsg',
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
        final uri = Uri.file(filePath).toString();
        final dbusResult = await Process.run('dbus-send', [
          '--session',
          '--dest=org.freedesktop.FileManager1',
          '--type=method_call',
          '/org/freedesktop/FileManager1',
          'org.freedesktop.FileManager1.ShowItems',
          'array:string:$uri',
          'string:',
        ]);
        
        if (dbusResult.exitCode != 0) {
          final dir = file.parent.path;
          await Process.run('xdg-open', [dir]);
        }
      }
    } catch (e) {
      debugPrint('Gagal membuka file manager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<CommitModel>>>(commitsProvider, (previous, next) {
      if (next is AsyncLoading) {
        setState(() => _loading = true);
      } else {
        _loadPreview();
      }
    });

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
                  if (_missingDates.isNotEmpty) ...[
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
                          Text('${_missingDates.length} hari belum ada kegiatan',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.accentOrange.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  _buildMergeToggle(colors),
                  const SizedBox(width: 12),
                  _buildGlobalResetButton(colors),
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
                          _buildFormatButton('docs', 'Docs', Icons.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: MouseRegion(
                      cursor: _exporting || _previewRows.isEmpty
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: ElevatedButton.icon(
                        onPressed: _exporting || _previewRows.isEmpty
                            ? null
                            : (_exportFormat == 'excel' ? _export : _exportDocs),
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
                                : 'Export Docs')),
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
              // Docs export options (with constrained height + scrollable)
              if (_exportFormat == 'docs')
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _downloadDefaultTemplate,
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Unduh Template Default'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      foregroundColor: colors.accentBlue,
                                      side: BorderSide(
                                        color: colors.accentBlue.withValues(alpha: 0.5),
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
                        : ReportPreviewTable(
                            rows: _previewRows,
                            onKegiatanChanged: _onKegiatanChanged,
                            onResetKegiatan: _onResetKegiatan,
                          ),
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

  Widget _buildGlobalResetButton(ThemeColors colors) {
    return FadeIn(
      delay: const Duration(milliseconds: 150),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: OutlinedButton.icon(
          onPressed: _previewRows.isEmpty ? null : _resetAllDrafts,
          icon: const Icon(Icons.restore, size: 14),
          label: const Text(
            'Reset Semua Edit',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.accentRed,
            side: BorderSide(
              color: colors.accentRed.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetAllDrafts() async {
    final colors = ThemeColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(color: colors.surfaceBorder.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.accentRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Reset Semua Edit',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus seluruh edit kegiatan kustom dan kembali ke default commit untuk bulan ini?',
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final calState = ref.read(calendarStateProvider);
      await DraftKegiatanStorage.clearMonthDrafts(calState.year, calState.month);
      _pendingDrafts.clear();
      await _loadPreview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Seluruh edit kustom bulan ini berhasil direset.'),
            backgroundColor: colors.accentGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildFormatButton(String format, String label, IconData icon) {
    final isSelected = _exportFormat == format;
    final colors = ThemeColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
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
      ),
    );
  }

  Widget _buildMergeToggle(ThemeColors colors) {
    return FadeIn(
      delay: const Duration(milliseconds: 150),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            final newValue = !_mergeDuplicates;
            setState(() => _mergeDuplicates = newValue);
            await _saveMergePreference(newValue);
            await _loadPreview();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _mergeDuplicates
                  ? colors.accentGreen.withValues(alpha: 0.1)
                  : colors.surfaceBorder.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(
                color: _mergeDuplicates
                    ? colors.accentGreen.withValues(alpha: 0.3)
                    : colors.surfaceBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _mergeDuplicates ? Icons.merge_type : Icons.format_list_bulleted,
                  size: 14,
                  color: _mergeDuplicates
                      ? colors.accentGreen
                      : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _mergeDuplicates ? 'Gabung' : 'Pisah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _mergeDuplicates
                        ? colors.accentGreen
                        : colors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
