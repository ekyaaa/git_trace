import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../lib/models/report_row_model.dart';
import '../lib/services/docx_template_engine.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  
  final variables = <String, String>{
    'nama': 'Test Nama',
    'nim': '12345',
    'prodi': 'TI',
    'mitra': 'PT Test',
    'pembimbing': 'AAAAA',
    'pembimbing_lapangan': 'AAAAA',
    'nama_mahasiswa': 'AAAAA',
    'nama_pembimbing': 'AAAAA',
    'nama_pembimbing_lapangan': 'AAAAA',
    'bulan': '06',
    'tahun': '2026',
  };
  
  final rows = [
    ReportRowModel(dayDate: 'Senin', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Test'),
  ];
  
  final result = await DocxTemplateEngine.generate(
    templateBytes: templateBytes,
    variables: variables,
    tableRows: rows,
  );
  
  // Extract text from result
  final archive = ZipDecoder().decodeBytes(result);
  final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
  final xmlStr = utf8.decode(docFile.content as List<int>);
  final doc = XmlDocument.parse(xmlStr);
  
  final tElements = doc.findAllElements('t', namespace: _nsW);
  
  print('=== ALL text in output ===');
  for (final t in tElements) {
    final text = t.innerText;
    if (text.trim().isNotEmpty) {
      print('  "$text"');
    }
  }
  
  print('\n=== Signature check ===');
  bool foundMahasiswa = false;
  bool foundPembimbing = false;
  bool foundPembimbingLapangan = false;
  for (final t in tElements) {
    final text = t.innerText;
    if (text.contains('AAAAA')) {
      print('  FOUND AAAAA: "$text"');
      if (text.contains('Mahasiswa') || text == ' AAAAA') foundMahasiswa = true;
    }
    if (text.contains('{{')) {
      print('  UNREPLACED: "$text"');
    }
  }
  
  if (!foundMahasiswa && !foundPembimbing && !foundPembimbingLapangan) {
    print('  WARNING: No AAAAA found at all!');
  }
}
