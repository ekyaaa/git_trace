import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../lib/models/report_row_model.dart';

const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

Uint8List _buildDocx(String documentBody) {
  final docXml = utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $documentBody
  </w:body>
</w:document>''');

  final ctXml = utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''');

  final relsXml = utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''');

  final docRelsXml = utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''');

  final archive = Archive();
  archive.addFile(ArchiveFile('[Content_Types].xml', ctXml.length, ctXml));
  archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, relsXml));
  archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, docRelsXml));
  archive.addFile(ArchiveFile('word/document.xml', docXml.length, docXml));

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

String _extractDocText(Uint8List docxBytes) {
  final archive = ZipDecoder().decodeBytes(docxBytes);
  final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
  final xml = utf8.decode(docFile.content as List<int>);
  final doc = XmlDocument.parse(xml);
  return doc.findAllElements('t', namespace: _nsW).map((e) => e.innerText).join('');
}

void _check(String testName, bool condition, String detail) {
  if (condition) {
    print('  PASS: $testName');
  } else {
    print('  FAIL: $testName — $detail');
  }
}

void main() {
  print('=== Test 1: Normal placeholder (no split) ===');
  {
    final body = '<w:p><w:r><w:t>Nama: {{nama}}</w:t></w:r></w:p>'
                 '<w:p><w:r><w:t>NIM: {{nim}}</w:t></w:r></w:p>';
    final docx = _buildDocx(body);
    final result = _replaceInDocx(docx, {'nama': 'John Doe', 'nim': '12345'});
    final text = _extractDocText(result);
    _check('nama replaced', text.contains('Nama: John Doe'), 'got: $text');
    _check('nim replaced', text.contains('NIM: 12345'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 2: Split placeholder across <w:t> runs ===');
  {
    final body = '<w:p>'
                 '<w:r><w:t>{{</w:t></w:r>'
                 '<w:r><w:t>nama</w:t></w:r>'
                 '<w:r><w:t>}}</w:t></w:r>'
                 '</w:p>';
    final docx = _buildDocx(body);
    final result = _replaceInDocx(docx, {'nama': 'Jane Smith'});
    final text = _extractDocText(result);
    _check('split placeholder replaced', text.contains('Jane Smith'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 3: Mixed normal + split ===');
  {
    final body = '<w:p><w:r><w:t>Prodi: {{prodi}}</w:t></w:r></w:p>'
                 '<w:p>'
                 '<w:r><w:t>{{</w:t></w:r>'
                 '<w:r><w:t>nama</w:t></w:r>'
                 '<w:r><w:t>}}</w:t></w:r>'
                 '</w:p>';
    final docx = _buildDocx(body);
    final result = _replaceInDocx(docx, {'prodi': 'TI', 'nama': 'Ali'});
    final text = _extractDocText(result);
    _check('normal prodi replaced', text.contains('Prodi: TI'), 'got: $text');
    _check('split nama replaced', text.contains('Ali'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 4: Table row with split placeholder ===');
  {
    final body = '''
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Info</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Data</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Hari/Tanggal</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Masuk</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Pulang</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Kegiatan</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p>
            <w:r><w:t>{{</w:t></w:r>
            <w:r><w:t>hari_tanggal</w:t></w:r>
            <w:r><w:t>}}</w:t></w:r>
          </w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_masuk}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_pulang}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{kegiatan}}</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
    ''';
    final docx = _buildDocx(body);
    final row = ReportRowModel(dayDate: 'Senin, 01/01', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Meeting');
    final result = _replaceInDocx(docx, {}, tableRows: [row]);
    final text = _extractDocText(result);
    _check('dayDate in table', text.contains('Senin, 01/01'), 'got: $text');
    _check('checkIn in table', text.contains('08:00'), 'got: $text');
    _check('checkOut in table', text.contains('17:00'), 'got: $text');
    _check('kegiatan in table', text.contains('Meeting'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 5: Full template (info + activity table) ===');
  {
    final body = '''
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Nama</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{nama}}</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p><w:r><w:t>NIM</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{nim}}</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Prodi</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{prodi}}</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Mitra</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{mitra}}</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Hari/Tanggal</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Masuk</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Pulang</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Kegiatan</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p>
            <w:r><w:t>{{</w:t></w:r>
            <w:r><w:t>hari_tanggal</w:t></w:r>
            <w:r><w:t>}}</w:t></w:r>
          </w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_masuk}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_pulang}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{kegiatan}}</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
    ''';
    final docx = _buildDocx(body);
    final row = ReportRowModel(dayDate: 'Senin, 01/01', checkIn: '08:00', checkOut: '17:00', kegiatan: 'Koding');
    final result = _replaceInDocx(docx, {
      'nama': 'Budi Santoso',
      'nim': '890123',
      'prodi': 'TI',
      'mitra': 'PT Maju Jaya',
    }, tableRows: [row]);
    final text = _extractDocText(result);
    _check('nama', text.contains('Budi Santoso'), 'got: $text');
    _check('nim', text.contains('890123'), 'got: $text');
    _check('prodi', text.contains('TI'), 'got: $text');
    _check('mitra', text.contains('PT Maju Jaya'), 'got: $text');
    _check('hari_tanggal', text.contains('Senin, 01/01'), 'got: $text');
    _check('jam_masuk', text.contains('08:00'), 'got: $text');
    _check('jam_pulang', text.contains('17:00'), 'got: $text');
    _check('kegiatan', text.contains('Koding'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 6: Multiple table rows ===');
  {
    final body = '''
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Info</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Data</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Hari/Tanggal</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Masuk</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Jam Pulang</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Kegiatan</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p><w:r><w:t>{{hari_tanggal}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_masuk}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{jam_pulang}}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>{{kegiatan}}</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
    ''';
    final docx = _buildDocx(body);
    final rows = [
      ReportRowModel(dayDate: 'Senin', checkIn: '08:00', checkOut: '17:00', kegiatan: 'A'),
      ReportRowModel(dayDate: 'Selasa', checkIn: '09:00', checkOut: '18:00', kegiatan: 'B'),
    ];
    final result = _replaceInDocx(docx, {}, tableRows: rows);
    final text = _extractDocText(result);
    _check('row1 day', text.contains('Senin'), 'got: $text');
    _check('row1 kegiatan', text.contains('A'), 'got: $text');
    _check('row2 day', text.contains('Selasa'), 'got: $text');
    _check('row2 kegiatan', text.contains('B'), 'got: $text');
    _check('no placeholders left', !text.contains('{{'), 'got: $text');
  }

  print('\n=== Test 7: Analyze real template ===');
  {
    final file = File('assets/templates/default_logbook_template.docx');
    if (!file.existsSync()) {
      print('  SKIP: Template file not found');
    } else {
      final templateBytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(templateBytes);
      final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
      final xmlStr = utf8.decode(docFile.content as List<int>);

      final placeholders = RegExp(r'\{\{[^}]+\}\}').allMatches(xmlStr).map((m) => m.group(0)).toSet();
      print('  Placeholders in template: $placeholders');

      final doc = XmlDocument.parse(xmlStr);
      final tElements = doc.findAllElements('t', namespace: _nsW);
      print('  Total <w:t> elements: ${tElements.length}');

      final splitTexts = <String>[];
      for (final t in tElements) {
        final text = t.innerText;
        if (text.contains('{') || text.contains('}')) {
          splitTexts.add(text);
        }
      }
      print('  Texts containing { or }: $splitTexts');
    }
  }

  print('\n=== Done ===');
}

Uint8List _replaceInDocx(Uint8List templateBytes, Map<String, String> variables, {List<ReportRowModel>? tableRows}) {
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
  if (documentXml == null) throw Exception('No document.xml');

  if (tableRows != null && tableRows.isNotEmpty) {
    _replaceTableRows(documentXml, tableRows);
  }

  _replaceAllVariables(documentXml, variables);

  final finalXml = documentXml.toXmlString(pretty: false);

  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));
  return Uint8List.fromList(ZipEncoder().encode(newArchive)!);
}

void _replaceAllVariables(XmlDocument doc, Map<String, String> variables) {
  if (variables.isEmpty) return;
  final allTElements = doc.findAllElements('t', namespace: _nsW).toList();
  for (final tElement in allTElements) {
    _replaceInTextNode(tElement, variables);
  }
}

void _replaceInTextNode(XmlElement tElement, Map<String, String> variables) {
  final value = tElement.innerText;
  if (value.isEmpty) return;

  var text = value;
  for (final entry in variables.entries) {
    final placeholder = '{{${entry.key}}}';
    if (text.contains(placeholder)) {
      text = text.replaceAll(placeholder, entry.value);
    }
  }
  if (text != value) {
    tElement.innerText = text;
    return;
  }

  if (text.contains('{{') && !text.contains('}}')) {
    _replaceSplitPlaceholder(tElement, variables);
  }
}

void _replaceSplitPlaceholder(XmlElement startElement, Map<String, String> variables) {
  XmlElement? blockAncestor;
  var current = startElement;
  while (current.parent != null) {
    current = current.parent as XmlElement;
    final tag = current.name.local;
    if (tag == 'p' || tag == 'tc') {
      blockAncestor = current;
      break;
    }
  }

  if (blockAncestor == null) return;

  final tElementsInBlock = blockAncestor.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 't')
      .toList();

  if (tElementsInBlock.length <= 1) return;

  final startIndex = tElementsInBlock.indexOf(startElement);
  if (startIndex < 0) return;

  var concatenated = '';
  final elementsUsed = <XmlElement>[];

  for (int i = startIndex; i < tElementsInBlock.length; i++) {
    concatenated += tElementsInBlock[i].innerText;
    elementsUsed.add(tElementsInBlock[i]);
    if (concatenated.contains('}}')) break;
  }

  var replaced = concatenated;
  var didReplace = false;
  for (final entry in variables.entries) {
    final placeholder = '{{${entry.key}}}';
    if (replaced.contains(placeholder)) {
      replaced = replaced.replaceAll(placeholder, entry.value);
      didReplace = true;
    }
  }

  if (!didReplace) return;

  elementsUsed.first.innerText = replaced;
  for (int i = 1; i < elementsUsed.length; i++) {
    elementsUsed[i].innerText = '';
  }
}

void _replaceTableRows(XmlDocument doc, List<ReportRowModel> tableRows) {
  final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
  if (allTables.length < 2) return;

  final activityTable = allTables[1];
  final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
  if (allRows.length < 2) return;

  final templateRows = <XmlElement>[];
  for (int i = 1; i < allRows.length; i++) {
    final rowText = _getRowText(allRows[i]);
    if (rowText.contains('{{')) {
      templateRows.add(allRows[i]);
    }
  }

  if (templateRows.isEmpty) return;

  final cloneSource = templateRows.first;

  for (final row in templateRows) {
    row.parent!.children.remove(row);
  }

  final remainingRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
  for (int i = 1; i < remainingRows.length; i++) {
    if (_getRowText(remainingRows[i]).trim().isEmpty) {
      remainingRows[i].parent!.children.remove(remainingRows[i]);
    }
  }

  for (final rowData in tableRows) {
    final newRow = _cloneRow(cloneSource);
    _replaceInClonedRow(newRow, rowData);
    activityTable.children.add(newRow);
  }
}

void _replaceInClonedRow(XmlElement row, ReportRowModel rowData) {
  final replacements = {
    'hari_tanggal': rowData.dayDate,
    'jam_masuk': rowData.checkIn,
    'jam_pulang': rowData.checkOut,
    'kegiatan': rowData.kegiatan,
  };

  final allTElements = row.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 't')
      .toList();

  for (final tElement in allTElements) {
    final value = tElement.innerText;
    if (value.isEmpty) continue;

    // Try direct replacement with full {{key}} placeholder
    var text = value;
    for (final entry in replacements.entries) {
      final placeholder = '{{${entry.key}}}';
      if (text.contains(placeholder)) {
        text = text.replaceAll(placeholder, entry.value);
      }
    }
    if (text != value) {
      tElement.innerText = text;
      continue;
    }

    // Handle split placeholder: text starts with {{ but no }}
    if (text.contains('{{') && !text.contains('}}')) {
      _replaceSplitPlaceholder(tElement, replacements);
    }
  }
}

String _getRowText(XmlElement tr) {
  return tr.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 't')
      .map((e) => e.innerText)
      .join('');
}

XmlElement _cloneRow(XmlElement original) {
  final xmlString = original.toXmlString();
  return XmlDocument.parse(xmlString).rootElement.copy();
}
