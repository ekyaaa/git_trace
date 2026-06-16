import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../lib/models/report_row_model.dart';
import '../lib/services/docx_template_engine.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() async {
  print('=== Simulating exact Flutter export flow ===\n');

  // Step 1: Load template (like the app does)
  final file = File('assets/templates/default_logbook_template.docx');
  final templateBytes = file.readAsBytesSync();
  print('Template loaded: ${templateBytes.length} bytes');

  // Step 2: Build variableMap exactly like docx_exporter.dart
  // Simulate: user filled Nama/NIM/Prodi/Mitra but TTD fields are empty
  final nama = 'BUDI SANTOSO';
  final nim = '1234567890';
  final prodi = 'Teknik Informatika';
  final mitra = 'PT Maju Jaya';
  final namaMahasiswa = '';  // empty - user didn't fill TTD
  final namaPembimbing = '';  // empty
  final namaPembimbingLapangan = '';  // empty

  final variableMap = <String, String>{
    'nama': nama,
    'nim': nim,
    'prodi': prodi,
    'mitra': mitra,
    'pembimbing': namaPembimbing,
    'pembimbing_lapangan': namaPembimbingLapangan,
    'nama_mahasiswa': namaMahasiswa.isNotEmpty ? namaMahasiswa : nama,
    'nama_pembimbing': namaPembimbing.isNotEmpty ? namaPembimbing : nama,
    'nama_pembimbing_lapangan': namaPembimbingLapangan.isNotEmpty ? namaPembimbingLapangan : nama,
    'bulan': '01',
    'tahun': '2025',
  };
  print('VariableMap: $variableMap');

  // Step 3: Build rows (empty - no commits for this month)
  final rows = <ReportRowModel>[
    ReportRowModel(dayDate: 'Senin, 06/01/2025', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Meeting'),
  ];

  // Step 4: Generate docx (exactly like the app)
  final docxBytes = await DocxTemplateEngine.generate(
    templateBytes: templateBytes,
    variables: variableMap,
    tableRows: rows,
  );
  print('\nGenerated docx: ${docxBytes.length} bytes');

  // Step 5: Save to file
  final outputPath = '/tmp/test_export_flow.docx';
  await File(outputPath).writeAsBytes(docxBytes);
  print('Saved to: $outputPath');

  // Step 6: Read back and verify
  print('\n=== POST-EXPORT VERIFICATION ===');
  final verifyArchive = ZipDecoder().decodeBytes(docxBytes);
  for (final f in verifyArchive.files) {
    if (f.name == 'word/document.xml') {
      final xmlContent = utf8.decode(f.content as List<int>);

      // Check for remaining placeholders
      final remaining = RegExp(r'\{\{.*?\}\}').allMatches(xmlContent).map((m) => m.group(0)).toSet();
      print('Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}');

      // Check for values
      print('Contains "BUDI SANTOSO": ${xmlContent.contains('BUDI SANTOSO')}');
      print('Contains "1234567890": ${xmlContent.contains('1234567890')}');
      print('Contains "Teknik Informatika": ${xmlContent.contains('Teknik Informatika')}');
      print('Contains "PT Maju Jaya": ${xmlContent.contains('PT Maju Jaya')}');

      // Check for empty placeholder replacements (placeholders replaced with empty string)
      // Look for text nodes that have just whitespace where a value should be
      final doc = XmlDocument.parse(xmlContent);
      final allT = doc.findAllElements('t', namespace: _nsW).toList();
      print('\nAll <w:t> elements with text:');
      for (final t in allT) {
        final text = t.innerText;
        if (text.trim().isNotEmpty || text.contains(' ')) {
          if (!text.contains('xml:space') || text.trim().isNotEmpty) {
            print('  "${text}"');
          }
        }
      }
    }
  }
}
