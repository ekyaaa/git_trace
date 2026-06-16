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

  // Simulate table rows (like the app would have)
  final tableRows = [
    ReportRowModel(
      dayDate: 'Senin, 02/06/2026',
      checkIn: '08:00',
      checkOut: '16:00',
      kegiatan: 'Pengembangan fitur export',
    ),
  ];

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

  // Do EXACTLY what the engine does
  _replaceTableRows(documentXml!, tableRows);
  _replaceAllVariables(documentXml!, variables);
  _injectSignatureFallback(documentXml!, variables);

  final finalXml = documentXml!.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

  final encoded = ZipEncoder().encode(newArchive);
  if (encoded == null) { print('ERROR: encode failed'); return; }

  await File('/tmp/test_real_engine.docx').writeAsBytes(encoded);
  print('Written /tmp/test_real_engine.docx (${encoded.length} bytes)');

  // Verify XML
  try {
    XmlDocument.parse(finalXml);
    print('XML valid: YES');
  } catch (e) {
    print('XML valid: NO - $e');
  }

  // Check placeholders
  final remaining = RegExp(r'\{\{.*?\}\}').allMatches(finalXml).map((m) => m.group(0)).toSet();
  print('Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}');
  
  // Print signature section from XML
  print('\n=== Signature section (last 3000 chars) ===');
  print(finalXml.substring(finalXml.length - 3000));
}

// Copies of engine functions for standalone test
void _replaceTableRows(XmlDocument doc, List<ReportRowModel> tableRows) {
  final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
  print('[Test] Tables found: ${allTables.length}');
  if (allTables.length < 2) { print('[Test] Less than 2 tables, skip'); return; }
  
  final activityTable = allTables[1];
  final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
  print('[Test] Activity table rows: ${allRows.length}');
  if (allRows.length < 2) return;

  XmlElement? templateRowElement;
  for (int i = 1; i < allRows.length; i++) {
    final rowText = allRows[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('');
    if (rowText.contains('{{')) {
      templateRowElement = allRows[i];
      print('[Test] Found template row at index $i');
      break;
    }
  }

  for (int i = allRows.length - 1; i >= 1; i--) {
    allRows[i].parent!.children.remove(allRows[i]);
  }

  if (templateRowElement != null) {
    for (final rowData in tableRows) {
      final newRow = templateRowElement.copy();
      final tElements = newRow.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').toList();
      final replacements = <String, String>{
        '{{hari_tanggal}}': rowData.dayDate,
        '{{jam_masuk}}': rowData.checkIn,
        '{{jam_pulang}}': rowData.checkOut,
        '{{kegiatan}}': rowData.kegiatan,
      };
      for (final tElement in tElements) {
        final text = tElement.innerText;
        if (text.isEmpty) continue;
        var newText = text;
        for (final entry in replacements.entries) {
          if (newText.contains(entry.key)) {
            newText = newText.replaceAll(entry.key, entry.value);
            break;
          }
        }
        if (newText != text) tElement.innerText = newText;
      }
      activityTable.children.add(newRow);
    }
  }
}

void _replaceAllVariables(XmlDocument doc, Map<String, String> variables) {
  final allTElements = doc.findAllElements('t', namespace: _nsW).toList();
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
    if (text != value) tElement.innerText = text;
  }
}

void _injectSignatureFallback(XmlDocument doc, Map<String, String> variables) {
  final signatureMap = <String, String>{
    'mahasiswa': 'nama_mahasiswa',
    'dosen pembimbing': 'nama_pembimbing',
    'pembimbing lapangan': 'nama_pembimbing_lapangan',
  };
  final allParagraphs = doc.findAllElements('p', namespace: _nsW).toList();
  for (int i = 0; i < allParagraphs.length; i++) {
    final para = allParagraphs[i];
    final paraText = para.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('').toLowerCase().trim();
    
    String? varKey;
    for (final entry in signatureMap.entries) {
      if (paraText == entry.key || paraText == '${entry.key},' || paraText == '${entry.key} ') {
        varKey = entry.value;
        break;
      }
    }
    if (varKey == null || !variables.containsKey(varKey) || variables[varKey]!.isEmpty) continue;
    
    final nameValue = variables[varKey]!;
    
    bool nameAlreadyPresent = false;
    for (int j = i + 1; j < allParagraphs.length && j <= i + 5; j++) {
      final nextText = allParagraphs[j].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('').trim();
      if (nextText == nameValue.trim()) { nameAlreadyPresent = true; break; }
      if (nextText.contains('{{') && nextText.contains('}}')) break;
      final nextLower = nextText.toLowerCase();
      if (nextLower.contains('dosen pembimbing') || nextLower.contains('pembimbing lapangan') || nextLower.contains('mengetahui') || nextLower == 'mahasiswa,') break;
    }
    if (nameAlreadyPresent) continue;

    for (int j = i + 1; j < allParagraphs.length && j <= i + 5; j++) {
      final nextPara = allParagraphs[j];
      final nextText = nextPara.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('').trim();
      if (nextText.isEmpty || nextText.contains('……………………')) {
        // Set text
        final tElements = nextPara.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').toList();
        if (tElements.isNotEmpty) {
          tElements.first.innerText = nameValue;
          for (int k = 1; k < tElements.length; k++) tElements[k].innerText = '';
        }
        print('[Test] Injected "$nameValue" after "$paraText"');
        break;
      }
    }
  }
}
