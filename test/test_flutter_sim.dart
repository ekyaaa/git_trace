import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:git_trace/models/report_row_model.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() async {
  // Simulate what Flutter rootBundle.load does
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  
  // Simulate the FULL engine pipeline exactly
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

  if (documentXml == null) { print('ERROR'); return; }

  // Simulate empty table rows (like when user has no commits)
  final tableRows = <ReportRowModel>[];

  // Simulate what the user filled in the form
  final variables = <String, String>{
    'nama': 'Alex',
    'nim': 'Alex',
    'prodi': 'Alex',
    'mitra': 'Alex',
    'pembimbing': 'Alex',
    'pembimbing_lapangan': 'Alex',
    'nama_mahasiswa': 'Alex',
    'nama_pembimbing': 'Alex',
    'nama_pembimbing_lapangan': 'Alex',
    'bulan': '06',
    'tahun': '2026',
  };

  print('[TEST] ====== SIMULATING ENGINE ======');
  
  _replaceTableRows(documentXml!, tableRows);
  _replaceAllVariables(documentXml!, variables);
  _injectSignatureFallback(documentXml!, variables);

  final finalXml = documentXml!.toXmlString(pretty: false);

  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

  final encoded = ZipEncoder().encode(newArchive);
  await File('/tmp/test_flutter_sim.docx').writeAsBytes(encoded!);

  // Verify
  print('\n[TEST] ====== VERIFICATION ======');
  print('[TEST] Output size: ${encoded.length} bytes');
  
  final remaining = RegExp(r'\{\{.*?\}\}').allMatches(finalXml).map((m) => m.group(0)).toSet();
  print('[TEST] Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}');
  
  print('[TEST] Has "Mahasiswa,": ${finalXml.contains('Mahasiswa,')}');
  print('[TEST] Has "Mengetahui,": ${finalXml.contains('Mengetahui,')}');
  print('[TEST] Has "Dosen Pembimbing,": ${finalXml.contains('Dosen Pembimbing,')}');
  print('[TEST] Has "Pembimbing Lapangan,": ${finalXml.contains('Pembimbing Lapangan,')}');
  print('[TEST] Has "Alex" (name): ${finalXml.contains('Alex')}');
  
  // Find all paragraphs with "Alex"
  final doc2 = XmlDocument.parse(finalXml);
  final allP = doc2.findAllElements('p', namespace: _nsW).toList();
  print('\n[TEST] All paragraphs after table:');
  bool afterTable = false;
  for (int i = 0; i < allP.length; i++) {
    final text = allP[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('');
    // Check if this is in signature area
    if (text.contains('Mahasiswa') || text.contains('Mengetahui') || text.contains('Dosen') || text.contains('Pembimbing') || text.contains('Alex') || text.contains('……………………') || afterTable) {
      afterTable = true;
      final hasT = allP[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').length;
      final tValues = allP[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).toList();
      print('  Para $i: text="$text" tElements=$hasT tValues=$tValues');
    }
  }
  
  // Count all <w:t> elements in final XML
  final allT = doc2.findAllElements('t', namespace: _nsW).toList();
  print('\n[TEST] Total <w:t> elements: ${allT.length}');
  final nonEmptyT = allT.where((t) => t.innerText.trim().isNotEmpty).toList();
  print('[TEST] Non-empty <w:t> elements: ${nonEmptyT.length}');
}

// Copies of engine functions
void _replaceTableRows(XmlDocument doc, List<ReportRowModel> tableRows) {
  final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
  print('[TEST] Tables: ${allTables.length}');
  if (allTables.length < 2) return;
  final activityTable = allTables[1];
  final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
  print('[TEST] Activity rows: ${allRows.length}');
  
  XmlElement? templateRowElement;
  for (int i = 1; i < allRows.length; i++) {
    final rowText = allRows[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('');
    if (rowText.contains('{{')) {
      templateRowElement = allRows[i];
      break;
    }
  }

  for (int i = allRows.length - 1; i >= 1; i--) {
    allRows[i].parent!.children.remove(allRows[i]);
  }

  if (templateRowElement != null && tableRows.isNotEmpty) {
    for (final rowData in tableRows) {
      final newRow = templateRowElement.copy();
      final tEls = newRow.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').toList();
      final reps = <String, String>{'{{hari_tanggal}}': rowData.dayDate, '{{jam_masuk}}': rowData.checkIn, '{{jam_pulang}}': rowData.checkOut, '{{kegiatan}}': rowData.kegiatan};
      for (final tEl in tEls) {
        var txt = tEl.innerText;
        for (final e in reps.entries) { if (txt.contains(e.key)) { txt = txt.replaceAll(e.key, e.value); break; } }
        if (txt != tEl.innerText) tEl.innerText = txt;
      }
      activityTable.children.add(newRow);
    }
  }
}

void _replaceAllVariables(XmlDocument doc, Map<String, String> variables) {
  if (variables.isEmpty) return;
  final allTElements = doc.findAllElements('t', namespace: _nsW).toList();
  int count = 0;
  for (final tElement in allTElements) {
    final value = tElement.innerText;
    if (value.isEmpty) continue;
    var text = value;
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      if (text.contains(placeholder)) {
        print('[TEST]   REPLACE "$placeholder" -> "${entry.value}" in "$text"');
        text = text.replaceAll(placeholder, entry.value);
        count++;
      }
    }
    if (text != value) tElement.innerText = text;
  }
  print('[TEST] Total replacements: $count');
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
      if (nextText == nameValue.trim()) { nameAlreadyPresent = true; print('[TEST] Fallback: name already present after "$paraText"'); break; }
      final nextLower = nextText.toLowerCase();
      if (nextLower.contains('dosen pembimbing') || nextLower.contains('pembimbing lapangan') || nextLower.contains('mengetahui') || nextLower == 'mahasiswa,') break;
    }
    if (nameAlreadyPresent) continue;

    for (int j = i + 1; j < allParagraphs.length && j <= i + 5; j++) {
      final nextPara = allParagraphs[j];
      final nextText = nextPara.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join('').trim();
      if (nextText.isEmpty || nextText.contains('……………………')) {
        final tEls = nextPara.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').toList();
        if (tEls.isNotEmpty) {
          tEls.first.innerText = nameValue;
          for (int k = 1; k < tEls.length; k++) tEls[k].innerText = '';
        }
        print('[TEST] Fallback injected "$nameValue" after "$paraText"');
        break;
      }
    }
  }
}
