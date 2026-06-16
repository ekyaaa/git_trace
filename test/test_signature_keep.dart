import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../lib/models/report_row_model.dart';
import '../lib/services/docx_template_engine.dart';

void main() async {
  final templateFile = File('assets/templates/default_logbook_template.docx');
  if (!templateFile.existsSync()) {
    print('ERROR: default template not found');
    exit(1);
  }
  
  final templateBytes = templateFile.readAsBytesSync();
  
  final variables = <String, String>{
    'nama': 'Test Nama',
    'nim': '1234567890',
    'prodi': 'Teknik Informatika',
    'mitra': 'PT Pembimbing Mitra',
    'pembimbing': 'Dosen A',
    'pembimbing_lapangan': 'Lapangan B',
    'nama_mahasiswa': 'Test Nama',
    'nama_pembimbing': 'Dosen A',
    'nama_pembimbing_lapangan': 'Lapangan B',
    'bulan': '06',
    'tahun': '2026',
  };
  
  final rows = [
    ReportRowModel(dayDate: 'Senin, 01/06/2026', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Melakukan testing keep-together'),
  ];
  
  print('=== Generating DOCX document ===');
  final resultBytes = await DocxTemplateEngine.generate(
    templateBytes: templateBytes,
    variables: variables,
    tableRows: rows,
  );
  
  print('=== Parsing generated DOCX XML ===');
  final archive = ZipDecoder().decodeBytes(resultBytes);
  final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
  final xmlStr = utf8.decode(docFile.content as List<int>);
  final doc = XmlDocument.parse(xmlStr);
  
  final body = doc.descendants.whereType<XmlElement>().firstWhere((e) => e.name.local == 'body');
  final children = body.children.whereType<XmlElement>().toList();
  
  // Find activity table
  int activityTableIdx = -1;
  for (int i = 0; i < children.length; i++) {
    if (children[i].name.local == 'tbl') {
      final text = children[i].descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .map((t) => t.innerText)
          .join(' ');
      if (text.contains('kegiatan') || text.contains('Hari, Tanggal')) {
        activityTableIdx = i;
      }
    }
  }
  
  if (activityTableIdx == -1) {
    print('FAIL: Activity table not found');
    exit(1);
  }
  
  // Find start of signature section
  int signatureStartIdx = -1;
  for (int i = activityTableIdx + 1; i < children.length; i++) {
    final text = children[i].descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join(' ');
    if (text.contains('Mahasiswa') || text.contains('Mengetahui') || text.contains('Tanda Tangan')) {
      signatureStartIdx = i;
      break;
    }
  }
  
  if (signatureStartIdx == -1) {
    print('FAIL: Signature start paragraph not found');
    exit(1);
  }
  
  print('Signature start index is: $signatureStartIdx');
  bool testPassed = true;
  
  print('=== Verifying body elements from index $signatureStartIdx onwards ===');
  for (int i = signatureStartIdx; i < children.length; i++) {
    final element = children[i];
    final text = element.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
    
    if (element.name.local == 'p') {
      final pPr = element.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'pPr')
          .firstOrNull;
      
      if (pPr == null) {
        print('  Body Paragraph $i ("$text"): FAIL - no pPr found');
        testPassed = false;
        continue;
      }
      
      final keepNext = pPr.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'keepNext')
          .firstOrNull;
      
      if (keepNext == null) {
        print('  Body Paragraph $i ("$text"): FAIL - no keepNext found');
        testPassed = false;
      } else {
        print('  Body Paragraph $i ("$text"): PASS (keepNext is present)');
      }
    } else if (element.name.local == 'tbl') {
      print('  Table found at element $i: verifying table elements');
      
      final trList = element.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'tr')
          .toList();
      
      for (int r = 0; r < trList.length; r++) {
        final tr = trList[r];
        final trPr = tr.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'trPr')
            .firstOrNull;
        
        if (trPr == null) {
          print('    Table Row $r: FAIL - no trPr found');
          testPassed = false;
          continue;
        }
        
        final cantSplit = trPr.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'cantSplit')
            .firstOrNull;
        
        if (cantSplit == null) {
          print('    Table Row $r: FAIL - no cantSplit found');
          testPassed = false;
        } else {
          print('    Table Row $r: PASS (cantSplit is present)');
        }
      }
      
      final cellParagraphs = element.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'p')
          .toList();
          
      for (int p = 0; p < cellParagraphs.length; p++) {
        final cp = cellParagraphs[p];
        final cpText = cp.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((t) => t.innerText)
            .join('');
        final cpPr = cp.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'pPr')
            .firstOrNull;
            
        if (cpPr == null) {
          print('    Cell Paragraph $p ("$cpText"): FAIL - no cpPr found');
          testPassed = false;
          continue;
        }
        
        final keepNext = cpPr.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'keepNext')
            .firstOrNull;
            
        if (keepNext == null) {
          print('    Cell Paragraph $p ("$cpText"): FAIL - no keepNext found');
          testPassed = false;
        } else {
          print('    Cell Paragraph $p ("$cpText"): PASS (keepNext is present)');
        }
      }
    }
  }
  
  if (testPassed) {
    print('\n=== ALL EXPANDED TESTS PASSED SUCCESSFULLY! ===');
  } else {
    print('\n=== SOME TESTS FAILED! ===');
    exit(1);
  }
}
