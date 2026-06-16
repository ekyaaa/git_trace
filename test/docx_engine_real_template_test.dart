import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../lib/models/report_row_model.dart';
import '../lib/services/docx_template_engine.dart';

String _extractDocText(List<int> docxBytes) {
  final archive = ZipDecoder().decodeBytes(docxBytes);
  final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
  final xml = utf8.decode(docFile.content as List<int>);
  return xml;
}

void _check(String testName, bool condition, String detail) {
  if (condition) {
    print('  PASS: $testName');
  } else {
    print('  FAIL: $testName - $detail');
  }
}

void main() async {
  print('=== Test: Real template with DocxTemplateEngine.generate ===');
  {
    final file = File('assets/templates/default_logbook_template.docx');
    if (!file.existsSync()) {
      print('  SKIP: Template file not found');
      return;
    }

    final templateBytes = file.readAsBytesSync();

    final variables = <String, String>{
      'nama': 'BUDI SANTOSO',
      'nim': '1234567890',
      'prodi': 'Teknik Informatika',
      'mitra': 'PT Maju Jaya',
      'pembimbing': 'Dr. Ahmad',
      'pembimbing_lapangan': 'Ir. Budi',
      'nama_mahasiswa': 'BUDI SANTOSO',
      'nama_pembimbing': 'Dr. Ahmad',
      'nama_pembimbing_lapangan': 'Ir. Budi',
      'bulan': '01',
      'tahun': '2025',
    };

    final rows = [
      ReportRowModel(dayDate: 'Senin, 06/01/2025', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Meeting'),
      ReportRowModel(dayDate: 'Selasa, 07/01/2025', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Coding'),
    ];

    print('  Variables: $variables');
    print('  Table rows: ${rows.length}');

    try {
      final result = await DocxTemplateEngine.generate(
        templateBytes: templateBytes,
        variables: variables,
        tableRows: rows,
      );

      final xmlContent = _extractDocText(result);

      // Check header table placeholders
      _check('{{nama}} replaced', !xmlContent.contains('{{nama}}'), 'still contains {{{{nama}}');
      _check('{{nim}} replaced', !xmlContent.contains('{{nim}}'), 'still contains {{{{nim}}');
      _check('{{prodi}} replaced', !xmlContent.contains('{{prodi}}'), 'still contains {{{{prodi}}');
      _check('{{mitra}} replaced', !xmlContent.contains('{{mitra}}'), 'still contains {{{{mitra}}');
      _check('{{pembimbing}} replaced', !xmlContent.contains('{{pembimbing}}'), 'still contains {{{{pembimbing}}');
      _check('{{pembimbing_lapangan}} replaced', !xmlContent.contains('{{pembimbing_lapangan}}'), 'still contains {{{{pembimbing_lapangan}}');

      // Check TTD placeholders
      _check('{{nama_mahasiswa}} replaced', !xmlContent.contains('{{nama_mahasiswa}}'), 'still contains {{{{nama_mahasiswa}}');
      _check('{{nama_pembimbing}} replaced', !xmlContent.contains('{{nama_pembimbing}}'), 'still contains {{{{nama_pembimbing}}');
      _check('{{nama_pembimbing_lapangan}} replaced', !xmlContent.contains('{{nama_pembimbing_lapangan}}'), 'still contains {{{{nama_pembimbing_lapangan}}');

      // Check no placeholders remain at all
      final remaining = RegExp(r'\{\{.*?\}\}').allMatches(xmlContent).map((m) => m.group(0)).toSet();
      _check('no placeholders remaining', remaining.isEmpty, 'remaining: $remaining');

      // Check values are present in the output
      _check('BUDI SANTOSO in output', xmlContent.contains('BUDI SANTOSO'), 'not found');
      _check('1234567890 in output', xmlContent.contains('1234567890'), 'not found');
      _check('Teknik Informatika in output', xmlContent.contains('Teknik Informatika'), 'not found');
      _check('PT Maju Jaya in output', xmlContent.contains('PT Maju Jaya'), 'not found');
      _check('Dr. Ahmad in output', xmlContent.contains('Dr. Ahmad'), 'not found');
      _check('Ir. Budi in output', xmlContent.contains('Ir. Budi'), 'not found');

      // Check table rows
      _check('Senin in output', xmlContent.contains('Senin, 06/01/2025'), 'not found');
      _check('Selasa in output', xmlContent.contains('Selasa, 07/01/2025'), 'not found');
      _check('Meeting in output', xmlContent.contains('Meeting'), 'not found');
      _check('Coding in output', xmlContent.contains('Coding'), 'not found');

      // Save the output for manual inspection
      final outputFile = File('/tmp/docx_engine_test_output.docx');
      await outputFile.writeAsBytes(result);
      print('  Output saved to: ${outputFile.path}');

    } catch (e, stack) {
      print('  ERROR: $e');
      print('  Stack: $stack');
    }
  }

  print('\n=== Done ===');
}
