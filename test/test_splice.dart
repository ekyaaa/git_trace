import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() {
  final file = File('assets/templates/default_logbook_template.docx');
  final templateBytes = file.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  String? rawXml;
  for (final f in archive.files) {
    if (f.name == 'word/document.xml') {
      rawXml = utf8.decode(f.content as List<int>);
    }
  }
  if (rawXml == null) throw Exception('No document.xml');

  final doc = XmlDocument.parse(rawXml);
  final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
  print('Tables: ${allTables.length}');

  final activityTable = allTables[1];
  final modifiedTableXml = activityTable.toXmlString(pretty: false);

  print('\n=== Modified table first 400 chars ===');
  print(modifiedTableXml.substring(0, 400));

  final origTableStart = rawXml.indexOf('<w:tbl>', rawXml.indexOf('<w:tbl>') + 1);
  final origTableEnd = rawXml.indexOf('</w:tbl>', origTableStart) + 8;
  print('\norigTableStart: $origTableStart');
  print('origTableEnd: $origTableEnd');

  final result = rawXml.substring(0, origTableStart) + modifiedTableXml + rawXml.substring(origTableEnd);

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

  var finalResult = result;
  for (final entry in variables.entries) {
    final placeholder = '{{${entry.key}}}';
    if (finalResult.contains(placeholder)) {
      finalResult = finalResult.replaceAll(placeholder, entry.value);
      print('Replaced: $placeholder -> ${entry.value}');
    } else {
      print('NOT FOUND: $placeholder');
    }
  }

  final remaining = RegExp(r'\{\{.*?\}\}').allMatches(finalResult).map((m) => m.group(0)).toSet();
  print('\nRemaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}');

  print('\n=== Value checks ===');
  print('Contains BUDI SANTOSO: ${finalResult.contains('BUDI SANTOSO')}');
  print('Contains 1234567890: ${finalResult.contains('1234567890')}');
  print('Contains Teknik Informatika: ${finalResult.contains('Teknik Informatika')}');
  print('Contains Dr. Ahmad: ${finalResult.contains('Dr. Ahmad')}');

  // Now test with EMPTY values like the real app might have
  print('\n=== TEST WITH EMPTY VALUES ===');
  final emptyVariables = <String, String>{
    'nama': 'BUDI',
    'nim': '123',
    'prodi': 'TI',
    'mitra': 'PT X',
    'pembimbing': '',
    'pembimbing_lapangan': '',
    'nama_mahasiswa': 'BUDI',
    'nama_pembimbing': 'BUDI',
    'nama_pembimbing_lapangan': 'BUDI',
    'bulan': '01',
    'tahun': '2025',
  };

  var emptyResult = result;
  for (final entry in emptyVariables.entries) {
    final placeholder = '{{${entry.key}}}';
    if (emptyResult.contains(placeholder)) {
      emptyResult = emptyResult.replaceAll(placeholder, entry.value);
      print('Replaced: $placeholder -> "${entry.value}"');
    } else {
      print('NOT FOUND: $placeholder');
    }
  }

  final emptyRemaining = RegExp(r'\{\{.*?\}\}').allMatches(emptyResult).map((m) => m.group(0)).toSet();
  print('\nRemaining placeholders: ${emptyRemaining.isEmpty ? "NONE" : emptyRemaining}');

  // Check if BUDI appears
  print('Contains BUDI: ${emptyResult.contains('BUDI')}');
}
