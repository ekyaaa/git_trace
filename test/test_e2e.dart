import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  // Step 1: Parse document.xml
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
  if (documentXml == null) { print('FAIL: no document.xml'); return; }

  // Step 2: Simulate table rows (like app does)
  final allTables = documentXml!.findAllElements('tbl', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
  print('Tables in template: ${allTables.length}');

  // Step 3: Replace variables (like app does)
  final variables = <String, String>{
    'nama': 'Ahmad Rizky',
    'nim': '41821001',
    'prodi': 'Teknik Informatika',
    'mitra': 'PT Telkom Indonesia',
    'pembimbing': 'Dr. Budi Santoso, M.Kom',
    'pembimbing_lapangan': 'Ir. Siti Aminah, M.T',
    'nama_mahasiswa': 'Ahmad Rizky',
    'nama_pembimbing': 'Dr. Budi Santoso, M.Kom',
    'nama_pembimbing_lapangan': 'Ir. Siti Aminah, M.T',
    'bulan': '06',
    'tahun': '2026',
  };

  final allTElements = documentXml.findAllElements('t', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
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
    if (text != value) {
      tElement.innerText = text;
      replaced++;
    }
  }
  print('Variables replaced: $replaced');

  // Step 4: Serialize and repackage
  final finalXml = documentXml.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

  final encoded = ZipEncoder().encode(newArchive);
  if (encoded == null) { print('FAIL: encode failed'); return; }

  final outFile = File('/tmp/test_e2e_output.docx');
  await outFile.writeAsBytes(encoded);
  print('Output: ${encoded.length} bytes');

  // Step 5: Verify
  try {
    XmlDocument.parse(finalXml);
    print('XML valid: YES');
  } catch (e) {
    print('XML valid: NO - $e');
  }

  // Check all TTD names
  print('\n=== TTD Check ===');
  print('Mahasiswa label: ${finalXml.contains('Mahasiswa,')}');
  print('Mahasiswa name: ${finalXml.contains('Ahmad Rizky')}');
  print('Mengetahui label: ${finalXml.contains('Mengetahui,')}');
  print('Dosen Pembimbing label: ${finalXml.contains('Dosen Pembimbing,')}');
  print('Pembimbing name: ${finalXml.contains('Dr. Budi Santoso, M.Kom')}');
  print('Pembimbing Lapangan label: ${finalXml.contains('Pembimbing Lapangan,')}');
  print('Plapangan name: ${finalXml.contains('Ir. Siti Aminah, M.T')}');

  // Check no remaining placeholders
  final remaining = RegExp(r'\{\{.*?\}\}').allMatches(finalXml).map((m) => m.group(0)).toSet();
  print('\nRemaining placeholders: ${remaining.isEmpty ? "NONE (good)" : remaining}');
}
