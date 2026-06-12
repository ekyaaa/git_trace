import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../models/commit_model.dart';
import '../models/report_variable_model.dart';
import 'docx_template_engine.dart';
import 'excel_exporter.dart';

class DocxExporter {
  static Future<String?> exportReport({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
    required ReportVariableModel variables,
    String? customTemplatePath,
    bool mergeDuplicates = true,
  }) async {
    try {
      // 1. Build report rows (same logic as Excel)
      final rows = await ExcelExporter.buildReportRows(
        commits,
        month,
        year,
        mergeDuplicates: mergeDuplicates,
      );
      if (rows.isEmpty) return null;

      // 2. Load template bytes
      Uint8List templateBytes;
      if (customTemplatePath != null && File(customTemplatePath).existsSync()) {
        templateBytes = await File(customTemplatePath).readAsBytes();
      } else {
        final byteData = await rootBundle.load(
          'assets/templates/default_logbook_template.docx',
        );
        templateBytes = byteData.buffer.asUint8List();
      }

      // 3. Prepare variable map
      final variableMap = <String, String>{
        'nama': variables.nama,
        'nim': variables.nim,
        'prodi': variables.prodi,
        'mitra': variables.mitra,
        'pembimbing': variables.pembimbing,
        'pembimbing_lapangan': variables.pembimbingLapangan,
        'nama_mahasiswa': variables.namaMahasiswa,
        'nama_pembimbing': variables.namaPembimbing,
        'nama_pembimbing_lapangan': variables.namaPembimbingLapangan,
        'bulan': month.toString().padLeft(2, '0'),
        'tahun': year.toString(),
      };

      // 4. Generate docx
      final docxBytes = await DocxTemplateEngine.generate(
        templateBytes: templateBytes,
        variables: variableMap,
        tableRows: rows,
      );

      // 5. Save file
      final fileName = 'GitTrace_Logbook_${year}_${month.toString().padLeft(2, '0')}.docx';
      final filePath = p.join(outputPath, fileName);
      final file = File(filePath);
      await file.writeAsBytes(docxBytes);

      return filePath;
    } catch (e, stack) {
      print('DOCX export error: $e');
      print('Stack: $stack');
      return null;
    }
  }

  static Future<String?> exportReportFromFile({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
    required ReportVariableModel variables,
    required String templatePath,
    bool mergeDuplicates = true,
  }) async {
    return exportReport(
      commits: commits,
      month: month,
      year: year,
      outputPath: outputPath,
      variables: variables,
      customTemplatePath: templatePath,
      mergeDuplicates: mergeDuplicates,
    );
  }
}
