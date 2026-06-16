import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import '../models/commit_model.dart';
import '../models/report_row_model.dart';
import '../models/report_variable_model.dart';
import 'excel_exporter.dart';
import 'docx_exporter.dart';

class PdfExporter {
  /// Exports monthly report to a PDF file.
  /// If customTemplatePath is null, it uses a native PDF layout with A4 & 1-inch margins.
  /// If customTemplatePath is provided, it populates the template and converts it via LibreOffice.
  static Future<String?> exportReport({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
    required ReportVariableModel variables,
    String? customTemplatePath,
    bool mergeDuplicates = true,
  }) async {
    // Path 1: Custom template provided -> convert via LibreOffice
    if (customTemplatePath != null) {
      return _exportViaLibreOffice(
        commits: commits,
        month: month,
        year: year,
        outputPath: outputPath,
        variables: variables,
        customTemplatePath: customTemplatePath,
        mergeDuplicates: mergeDuplicates,
      );
    }

    // Path 2: Default template -> native clean A4 PDF generation (matching Google Docs layout)
    return _exportNativePdf(
      commits: commits,
      month: month,
      year: year,
      outputPath: outputPath,
      variables: variables,
      mergeDuplicates: mergeDuplicates,
    );
  }

  /// Populates custom template and converts to PDF via headless LibreOffice
  static Future<String?> _exportViaLibreOffice({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
    required ReportVariableModel variables,
    required String customTemplatePath,
    bool mergeDuplicates = true,
  }) async {
    try {
      // 1. Generate populated Word document
      final tempDocxPath = await DocxExporter.exportReport(
        commits: commits,
        month: month,
        year: year,
        outputPath: outputPath,
        variables: variables,
        customTemplatePath: customTemplatePath,
        mergeDuplicates: mergeDuplicates,
      );

      if (tempDocxPath == null) return null;

      final docxFile = File(tempDocxPath);
      if (!docxFile.existsSync()) return null;

      // 2. Run LibreOffice to convert DOCX to PDF
      final result = await Process.run('libreoffice', [
        '--headless',
        '--convert-to',
        'pdf',
        '--outdir',
        outputPath,
        tempDocxPath,
      ]);

      // 3. Clean up temp DOCX
      try {
        await docxFile.delete();
      } catch (_) {}

      if (result.exitCode != 0) {
        print('[PdfExport] LibreOffice CLI failed: ${result.stderr}');
        return null;
      }

      // 4. Return the converted PDF path
      final docxName = p.basename(tempDocxPath);
      final pdfName = docxName.replaceAll(RegExp(r'\.docx$'), '.pdf');
      final pdfPath = p.join(outputPath, pdfName);

      if (File(pdfPath).existsSync()) {
        return pdfPath;
      }
      return null;
    } catch (e) {
      print('[PdfExport] LibreOffice path error: $e');
      return null;
    }
  }

  /// Generates PDF programmatically matching default template exactly (A4, 1-inch margins)
  static Future<String?> _exportNativePdf({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
    required ReportVariableModel variables,
    bool mergeDuplicates = true,
  }) async {
    try {
      final rows = await ExcelExporter.buildReportRows(
        commits,
        month,
        year,
        mergeDuplicates: mergeDuplicates,
      );
      if (rows.isEmpty) return null;

      final pdf = pw.Document();

      final effectiveNamaMahasiswa = variables.namaMahasiswa.isNotEmpty ? variables.namaMahasiswa : variables.nama;
      final effectiveNamaPembimbing = variables.namaPembimbing.isNotEmpty ? variables.namaPembimbing : variables.nama;
      final effectiveNamaPembimbingLapangan = variables.namaPembimbingLapangan.isNotEmpty ? variables.namaPembimbingLapangan : variables.nama;

      final baseFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();
      
      final titleStyle = pw.TextStyle(font: boldFont, fontSize: 13);
      final subtitleStyle = pw.TextStyle(font: boldFont, fontSize: 11);
      final labelStyle = pw.TextStyle(font: boldFont, fontSize: 10);
      final textStyle = pw.TextStyle(font: baseFont, fontSize: 10);
      final headerCellStyle = pw.TextStyle(font: boldFont, fontSize: 9);
      final cellStyle = pw.TextStyle(font: baseFont, fontSize: 9);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(72), // Exactly 1-inch margin on all sides (72 points)
          header: (pw.Context context) {
            if (context.pageNumber == 1) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('LOG BOOK KEGIATAN', style: titleStyle),
                  pw.Text('PROGRAM MAGANG INDUSTRI', style: subtitleStyle),
                  pw.SizedBox(height: 20),
                ],
              );
            }
            return pw.SizedBox();
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Metadata header grid (6 rows matching default Word template)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(130),
                    1: const pw.FixedColumnWidth(10),
                    2: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildMetaRow('Nama', variables.nama, labelStyle, textStyle),
                    _buildMetaRow('NIM', variables.nim, labelStyle, textStyle),
                    _buildMetaRow('Program Studi', variables.prodi, labelStyle, textStyle),
                    _buildMetaRow('Nama Mitra Industri', variables.mitra, labelStyle, textStyle),
                    _buildMetaRow('Dosen Pembimbing', variables.namaPembimbing.isNotEmpty ? variables.namaPembimbing : '-', labelStyle, textStyle),
                    _buildMetaRow('Pembimbing Lapangan', variables.namaPembimbingLapangan.isNotEmpty ? variables.namaPembimbingLapangan : '-', labelStyle, textStyle),
                  ],
                ),
              ),
              
              // Activities table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(110), // Hari, Tanggal
                  1: const pw.FixedColumnWidth(55),  // Jam Masuk
                  2: const pw.FixedColumnWidth(55),  // Jam Pulang
                  3: const pw.FlexColumnWidth(),     // Kegiatan
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildHeaderCell('Hari, Tanggal', headerCellStyle, align: pw.TextAlign.center),
                      _buildHeaderCell('Jam Masuk', headerCellStyle, align: pw.TextAlign.center),
                      _buildHeaderCell('Jam Pulang', headerCellStyle, align: pw.TextAlign.center),
                      _buildHeaderCell('Kegiatan', headerCellStyle, align: pw.TextAlign.center),
                    ],
                  ),
                  // Table Data
                  ...rows.map((row) {
                    return pw.TableRow(
                      children: [
                        _buildDataCell(row.dayDate, cellStyle, padding: 5),
                        _buildDataCell(row.checkIn, cellStyle, align: pw.TextAlign.center, padding: 5),
                        _buildDataCell(row.checkOut, cellStyle, align: pw.TextAlign.center, padding: 5),
                        _buildDataCell(row.kegiatan, cellStyle, padding: 5),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 32),

              // Signature block (keeps it together so it doesn't break onto a new page alone)
              pw.Inseparable(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left block (Mahasiswa)
                        pw.Expanded(
                          flex: 1,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('Mahasiswa,', style: textStyle),
                              pw.SizedBox(height: 50),
                              pw.Text(effectiveNamaMahasiswa, style: pw.TextStyle(font: boldFont, fontSize: 10, decoration: pw.TextDecoration.underline)),
                              pw.Text('NIM. ${variables.nim}', style: textStyle),
                            ],
                          ),
                        ),
                        // Middle/Right block (Mengetahui)
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('Mengetahui,', style: textStyle),
                              pw.SizedBox(height: 8),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text('Dosen Pembimbing,', style: textStyle),
                                        pw.SizedBox(height: 42),
                                        pw.Text(effectiveNamaPembimbing, style: pw.TextStyle(font: boldFont, fontSize: 10, decoration: pw.TextDecoration.underline)),
                                        pw.Text('NIDN. ____________', style: textStyle),
                                      ],
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text('Pembimbing Lapangan,', style: textStyle),
                                        pw.SizedBox(height: 42),
                                        pw.Text(effectiveNamaPembimbingLapangan, style: pw.TextStyle(font: boldFont, fontSize: 10, decoration: pw.TextDecoration.underline)),
                                        pw.Text('NIP/NIK. ____________', style: textStyle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final fileName = 'GitTrace_Report_${year}_${month.toString().padLeft(2, '0')}.pdf';
      final filePath = p.join(outputPath, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e, stack) {
      print('[PdfExport] Native export failed error: $e');
      print('[PdfExport] Stack: $stack');
      return null;
    }
  }

  static pw.TableRow _buildMetaRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle textStyle) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: labelStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(':', style: labelStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: textStyle),
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text, pw.TextStyle style, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.TextStyle style, {pw.TextAlign align = pw.TextAlign.left, double padding = 4}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
}
