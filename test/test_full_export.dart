import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);
  
  // Simulate full engine flow
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
  
  // Replace variables like the engine does
  final variables = <String, String>{
    'nama': 'Test Nama',
    'nim': '12345',
    'prodi': 'TI',
    'mitra': 'PT Test',
    'pembimbing': 'Dr. Test',
    'pembimbing_lapangan': 'Mr. Field',
    'nama_mahasiswa': 'Test Nama Mahasiswa',
    'nama_pembimbing': 'Dr. Test Pembimbing',
    'nama_pembimbing_lapangan': 'Mr. Test Lapangan',
    'bulan': '06',
    'tahun': '2026',
  };
  
  // Find all <w:t> elements and replace
  final allTElements = documentXml!.findAllElements('t', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
  print('Found ${allTElements.length} <w:t> elements');
  
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
      print('  Replaced: "$value" -> "$text"');
    }
  }
  
  print('Total replaced: $replaced');
  
  final finalXml = documentXml.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));
  
  final encoded = ZipEncoder().encode(newArchive);
  await File('/tmp/test_full_export.docx').writeAsBytes(encoded!);
  
  print('\nOutput: /tmp/test_full_export.docx (${encoded.length} bytes)');
  
  // Verify
  try {
    XmlDocument.parse(finalXml);
    print('XML valid');
  } catch (e) {
    print('XML INVALID: $e');
  }
  
  // Check signature section
  final sigLabels = ['Mahasiswa,', 'Mengetahui,', 'Dosen Pembimbing,', 'Pembimbing Lapangan,'];
  final sigNames = ['Test Nama Mahasiswa', 'Dr. Test Pembimbing', 'Mr. Test Lapangan'];
  
  for (final label in sigLabels) {
    if (finalXml.contains(label)) {
      print('Found label: $label');
    }
  }
  for (final name in sigNames) {
    if (finalXml.contains(name)) {
      print('Found name: $name');
    }
  }
}
