import 'dart:io';
import 'package:flutter/material.dart';
import 'package:git_trace/models/commit_model.dart';
import 'package:git_trace/models/report_variable_model.dart';
import 'package:git_trace/services/pdf_exporter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  SharedPreferences.setMockInitialValues({});

  print('=== Running PDF Export Test ===');

  final commits = [
    CommitModel(
      hash: 'hash1',
      shortHash: 'hash1',
      authorName: 'Budi Santoso',
      authorEmail: 'budi@example.com',
      timestamp: DateTime(2026, 6, 1, 9, 30),
      subject: 'feat: setup project repository structure',
      repoName: 'e-commerce-app',
      repoPath: '/path/to/repo',
    ),
    CommitModel(
      hash: 'hash2',
      shortHash: 'hash2',
      authorName: 'Budi Santoso',
      authorEmail: 'budi@example.com',
      timestamp: DateTime(2026, 6, 2, 10, 15),
      subject: 'fix: resolving auth validation bugs',
      repoName: 'e-commerce-app',
      repoPath: '/path/to/repo',
    ),
  ];

  final variables = ReportVariableModel(
    nama: 'Budi Santoso',
    nim: '1234567890',
    prodi: 'Teknik Informatika',
    mitra: 'PT Tech Innovation',
    namaMahasiswa: 'Budi Santoso',
    namaPembimbing: 'Dr. Ahmad Fauzi',
    namaPembimbingLapangan: 'Ir. Hendra Wijaya',
  );

  final outputPath = '/tmp';
  
  final filePath = await PdfExporter.exportReport(
    commits: commits,
    month: 6,
    year: 2026,
    outputPath: outputPath,
    variables: variables,
    mergeDuplicates: true,
  );

  if (filePath != null) {
    print('PDF generated successfully at: $filePath');
    final file = File(filePath);
    if (file.existsSync()) {
      print('File size: ${file.lengthSync()} bytes');
      print('=== PDF Export Test PASSED ===');
    } else {
      print('Error: PDF file does not exist at path!');
    }
  } else {
    print('PDF generation failed!');
  }
}
