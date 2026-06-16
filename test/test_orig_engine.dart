import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:git_trace/models/report_row_model.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  final newArchive = Archive();
  XmlDocument? documentXml;
  for (int i = 0; i < archive.files.length; i++) {
    final file = archive.files[i];
    if (file.name == 'word/document.xml') {
      final xmlString = utf8.decode(file.content as List<int>);
      documentXml = XmlDocument.parse(xmlString);
    } else {
      newArchive.addFile(file);
    }
  }
  if (documentXml == null) { print('ERROR: no document.xml'); return; }

  final tableRows = [
    ReportRowModel(dayDate: 'Senin, 02/06/2026', checkIn: '08:00', checkOut: '16:00', kegiatan: 'Pengembangan fitur export'),
  ];

  final variables = <String, String>{
    'nama': 'Ahmad Rizky', 'nim': '41821001', 'prodi': 'Teknik Informatika',
    'mitra': 'PT Telkom', 'pembimbing': 'Dr. Budi', 'pembimbing_lapangan': 'Ir. Siti',
    'nama_mahasiswa': 'Ahmad Rizky', 'nama_pembimbing': 'Dr. Budi Santoso, M.Kom',
    'nama_pembimbing_lapangan': 'Ir. Siti Aminah, M.T', 'bulan': '06', 'tahun': '2026',
  };

  // Simulate _replaceTableRows
  final allTables = documentXml!.findAllElements('tbl', namespace: _nsW).toList();
  print('Tables: ${allTables.length}');

  // Simulate _replaceAllVariables
  final allTElements = documentXml.findAllElements('t', namespace: _nsW).toList();
  int replaced = 0;
  for (final tElement in allTElements) {
    final value = tElement.innerText;
    if (value.isEmpty) continue;
    var text = value;
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      if (text.contains(placeholder)) {
        text = text.replaceAll(placeholder, entry.value);
      }
    }
    if (text != value) { tElement.innerText = text; replaced++; }
  }
  print('Replaced: $replaced');

  final finalXml = documentXml.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

  final encoded = ZipEncoder().encode(newArchive);
  await File('/tmp/test_orig_engine_output.docx').writeAsBytes(encoded!);

  // Check
  print('Remaining placeholders: ${RegExp(r'\{\{.*?\}\}').allMatches(finalXml).map((m) => m.group(0)).toSet()}');
  print('Has Mahasiswa,: ${finalXml.contains('Mahasiswa,')}');
  print('Has Dosen Pembimbing,: ${finalXml.contains('Dosen Pembimbing,')}');
  print('Has Pembimbing Lapangan,: ${finalXml.contains('Pembimbing Lapangan,')}');
  print('Has Ahmad Rizky: ${finalXml.contains('Ahmad Rizky')}');
  print('Has Dr. Budi: ${finalXml.contains('Dr. Budi Santoso, M.Kom')}');
  print('Has Ir. Siti: ${finalXml.contains('Ir. Siti Aminah, M.T')}');
  print('Output: ${encoded.length} bytes');
}
