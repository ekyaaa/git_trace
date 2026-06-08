import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../models/commit_model.dart';
import '../models/report_row_model.dart';
import '../services/work_hours_storage.dart';

class ExcelExporter {
  /// Exports monthly report to an Excel file.
  /// Returns the file path of the created file, or null on failure.
  static Future<String?> exportReport({
    required List<CommitModel> commits,
    required int month,
    required int year,
    required String outputPath,
  }) async {
    try {
      // Initialize Indonesian locale
      final dateFormatter = DateFormat('EEEE, d MMM yyyy', 'id_ID');

      // Group commits by date
      final commitsByDate = <DateTime, List<CommitModel>>{};
      for (final commit in commits) {
        final dateKey = commit.dateOnly;
        commitsByDate.putIfAbsent(dateKey, () => []).add(commit);
      }

      // Generate target dates (all weekdays, and weekends with commits)
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final sortedDates = <DateTime>[];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
        final hasCommits = commitsByDate.containsKey(date);

        if (!isWeekend || hasCommits) {
          sortedDates.add(date);
        }
      }

      // Build report rows
      final rows = <ReportRowModel>[];
      for (final date in sortedDates) {
        final dateCommits = commitsByDate[date] ?? [];
        // Sort commits by timestamp (earliest first)
        dateCommits.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Get working hours
        final dateKey =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final workHours = await WorkHoursStorage.getWorkHours(dateKey);

        // Format kegiatan
        final kegiatan = dateCommits
            .map((c) => '[${c.repoName}] ${c.subject}')
            .join('\n');

        rows.add(ReportRowModel(
          dayDate: dateFormatter.format(date),
          checkIn: workHours?.checkIn ?? '08.00',
          checkOut: workHours?.checkOut ?? '17.00',
          kegiatan: kegiatan,
        ));
      }

      // Create Excel
      final excel = Excel.createExcel();
      final sheetName = 'Laporan $month-$year';
      final sheet = excel[sheetName];

      // Remove default "Sheet1"
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Header style
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D0D0D0'),
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Data style
      final dataStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: VerticalAlign.Top,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

      final dataStyleWrap = CellStyle(
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 11,
        verticalAlign: VerticalAlign.Top,
        textWrapping: TextWrapping.WrapText,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Write headers
      final headers = ['Hari, Tanggal', 'Jam Masuk', 'Jam Pulang', 'Kegiatan'];
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // Write data rows
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final rowIndex = i + 1;

        // Column A: Hari, Tanggal
        final cellA = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        cellA.value = TextCellValue(row.dayDate);
        cellA.cellStyle = dataStyle;

        // Column B: Jam Masuk
        final cellB = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        cellB.value = TextCellValue(row.checkIn);
        cellB.cellStyle = dataStyle;

        // Column C: Jam Pulang
        final cellC = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        );
        cellC.value = TextCellValue(row.checkOut);
        cellC.cellStyle = dataStyle;

        // Column D: Kegiatan
        final cellD = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        cellD.value = TextCellValue(row.kegiatan);
        cellD.cellStyle = dataStyleWrap;
      }

      // Set column widths
      sheet.setColumnWidth(0, 28); // Hari, Tanggal
      sheet.setColumnWidth(1, 12); // Jam Masuk
      sheet.setColumnWidth(2, 12); // Jam Pulang
      sheet.setColumnWidth(3, 60); // Kegiatan (wide)

      // Save file
      final fileName = 'GitTrace_Report_${year}_${month.toString().padLeft(2, '0')}.xlsx';
      final filePath = p.join(outputPath, fileName);
      final fileBytes = excel.save();

      if (fileBytes == null) return null;

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Returns the list of dates that have commits but no working hours set.
  static Future<List<String>> getMissingWorkHoursDates(
    List<CommitModel> commits,
    int month,
    int year,
  ) async {
    final commitsByDate = <DateTime, List<CommitModel>>{};
    for (final commit in commits) {
      final dateKey = commit.dateOnly;
      commitsByDate.putIfAbsent(dateKey, () => []).add(commit);
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final missing = <String>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final hasCommits = commitsByDate.containsKey(date);

      if (!isWeekend || hasCommits) {
        final dateKey =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hours = await WorkHoursStorage.getWorkHours(dateKey);
        if (hours == null) {
          missing.add(dateKey);
        }
      }
    }

    missing.sort();
    return missing;
  }

  /// Builds report rows for preview (without saving to file).
  static Future<List<ReportRowModel>> buildReportRows(
    List<CommitModel> commits,
    int month,
    int year,
  ) async {
    final dateFormatter = DateFormat('EEEE, d MMM yyyy', 'id_ID');

    final commitsByDate = <DateTime, List<CommitModel>>{};
    for (final commit in commits) {
      final dateKey = commit.dateOnly;
      commitsByDate.putIfAbsent(dateKey, () => []).add(commit);
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final sortedDates = <DateTime>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final hasCommits = commitsByDate.containsKey(date);

      if (!isWeekend || hasCommits) {
        sortedDates.add(date);
      }
    }

    final rows = <ReportRowModel>[];
    for (final date in sortedDates) {
      final dateCommits = commitsByDate[date] ?? [];
      dateCommits.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final dateKey =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final workHours = await WorkHoursStorage.getWorkHours(dateKey);

      final kegiatan = dateCommits
          .map((c) => '[${c.repoName}] ${c.subject}')
          .join('\n');

      rows.add(ReportRowModel(
        dayDate: dateFormatter.format(date),
        checkIn: workHours?.checkIn ?? '08.00',
        checkOut: workHours?.checkOut ?? '17.00',
        kegiatan: kegiatan,
      ));
    }

    return rows;
  }
}
