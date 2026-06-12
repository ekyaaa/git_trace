import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/report_row_model.dart';

class DocxTemplateEngine {
  static const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  static Future<Uint8List> generate({
    required Uint8List templateBytes,
    required Map<String, String> variables,
    required List<ReportRowModel> tableRows,
  }) async {
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

    if (documentXml == null) {
      throw Exception('word/document.xml not found in template');
    }

    print('[DocxEngine] tableRows count: ${tableRows.length}');
    if (tableRows.isNotEmpty) {
      print('[DocxEngine] first row: dayDate="${tableRows.first.dayDate}", checkIn="${tableRows.first.checkIn}", checkOut="${tableRows.first.checkOut}", kegiatan="${tableRows.first.kegiatan}"');
    }

    _replaceTableRows(documentXml, tableRows);
    _replaceAllVariables(documentXml, variables);

    final finalXml = documentXml.toXmlString(pretty: false);

    final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
    newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

    final encoded = ZipEncoder().encode(newArchive);
    if (encoded == null) {
      throw Exception('Failed to encode docx archive');
    }
    return Uint8List.fromList(encoded);
  }

  static void _replaceAllVariables(XmlDocument doc, Map<String, String> variables) {
    if (variables.isEmpty) return;

    bool anyReplaced = false;
    final allTElements = doc.findAllElements('t', namespace: _nsW).toList();
    for (final tElement in allTElements) {
      if (_replaceInTextNode(tElement, variables)) {
        anyReplaced = true;
      }
    }

    if (!anyReplaced) {
      _replaceAllVariablesByLabel(doc, variables);
    }
  }

  static void _replaceAllVariablesByLabel(XmlDocument doc, Map<String, String> variables) {
    final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
    if (allTables.isEmpty) return;

    final headerTable = allTables.first;
    final rows = headerTable.findAllElements('tr', namespace: _nsW).toList();

    final labelMap = <String, String>{
      'nama': 'nama',
      'nim': 'nim',
      'program studi': 'prodi',
      'nama mitra industri': 'mitra',
      'dosen pembimbing': 'pembimbing',
      'pembimbing lapangan': 'pembimbing_lapangan',
    };

    for (final row in rows) {
      final cells = row.findAllElements('tc', namespace: _nsW).toList();
      if (cells.length < 2) continue;

      final labelCell = cells[0];
      final labelTElements = labelCell.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .toList();
      if (labelTElements.isEmpty) continue;

      final labelText = labelTElements.map((e) => e.innerText).join('').toLowerCase().trim();

      String? varKey;
      for (final entry in labelMap.entries) {
        if (labelText.contains(entry.key)) {
          varKey = entry.value;
          break;
        }
      }

      if (varKey == null || !variables.containsKey(varKey)) continue;
      if (variables[varKey]!.isEmpty) continue;

      final valueCell = cells[1];
      final valueTElements = valueCell.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .toList();

      if (valueTElements.isNotEmpty) {
        valueTElements.first.innerText = variables[varKey]!;
        for (int i = 1; i < valueTElements.length; i++) {
          valueTElements[i].innerText = '';
        }
      }
    }
  }

  static bool _replaceInTextNode(XmlElement tElement, Map<String, String> variables) {
    final value = tElement.innerText;
    if (value.isEmpty) return false;

    var text = value;
    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      if (text.contains(placeholder)) {
        text = text.replaceAll(placeholder, entry.value);
      }
    }
    if (text != value) {
      tElement.innerText = text;
      return true;
    }

    if (text.contains('{{') && !text.contains('}}')) {
      _replaceSplitPlaceholder(tElement, variables);
      return true;
    }

    return false;
  }

  static void _replaceSplitPlaceholder(XmlElement startElement, Map<String, String> variables) {
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

  static void _replaceTableRows(XmlDocument doc, List<ReportRowModel> tableRows) {
    final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
    print('[DocxEngine] Tables found: ${allTables.length}');
    if (allTables.length < 2) {
      print('[DocxEngine] WARNING: Less than 2 tables, skipping row replacement');
      return;
    }

    final activityTable = allTables[1];
    final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
    print('[DocxEngine] Activity table rows: ${allRows.length}');
    if (allRows.length < 2) return;

    for (int i = 0; i < allRows.length; i++) {
      final rowText = _getRowText(allRows[i]);
      print('[DocxEngine]   Row $i: "${rowText.length > 80 ? rowText.substring(0, 80) : rowText}"');
    }

    XmlElement? templateRowElement;

    for (int i = 1; i < allRows.length; i++) {
      final rowText = _getRowText(allRows[i]);
      if (rowText.contains('{{')) {
        templateRowElement = allRows[i];
        print('[DocxEngine] Found template row with {{{{}}}} at index $i');
        break;
      }
    }

    if (templateRowElement == null) {
      print('[DocxEngine] No template row with {{{{}}}}, will use _buildEmptyRow');
    }

    for (int i = allRows.length - 1; i >= 1; i--) {
      allRows[i].parent!.children.remove(allRows[i]);
    }
    print('[DocxEngine] Removed ${allRows.length - 1} non-header rows');

    if (templateRowElement != null) {
      print('[DocxEngine] Adding ${tableRows.length} rows from template');
      for (int i = 0; i < tableRows.length; i++) {
        final newRow = _buildRowFromTemplate(templateRowElement, tableRows[i]);
        activityTable.children.add(newRow);
      }
    } else if (allRows.isNotEmpty) {
      final columnCount = _getGridColumnCount(allRows.first);
      print('[DocxEngine] Adding ${tableRows.length} rows via _buildEmptyRow (columnCount=$columnCount)');
      for (final rowData in tableRows) {
        final newRow = _buildEmptyRow(columnCount, rowData);
        activityTable.children.add(newRow);
      }
    }

    final finalRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
    print('[DocxEngine] Final activity table rows: ${finalRows.length}');
    if (finalRows.length > 1) {
      final firstDataRowT = finalRows[1].descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .toList();
      final firstRowText = firstDataRowT.map((t) => t.innerText).join(' | ');
      print('[DocxEngine] First data row content: "$firstRowText"');
    }
  }

  static XmlElement _buildRowFromTemplate(XmlElement templateRow, ReportRowModel rowData) {
    final newRow = templateRow.copy();

    final tElements = newRow.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .toList();

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

      if (newText != text) {
        tElement.innerText = newText;
      }
    }

    return newRow;
  }

  static int _getGridColumnCount(XmlElement headerRow) {
    return headerRow.findAllElements('tc', namespace: _nsW).length;
  }

  static XmlElement _buildEmptyRow(int columnCount, ReportRowModel rowData) {
    final positionalValues = [
      rowData.dayDate,
      rowData.checkIn,
      rowData.checkOut,
      rowData.kegiatan,
    ];

    final rowXml = StringBuffer('<w:tr xmlns:w="$_nsW">');
    for (int i = 0; i < columnCount; i++) {
      final text = i < positionalValues.length ? _escapeXmlText(positionalValues[i]) : '';
      rowXml.write('<w:tc><w:p><w:r><w:t xml:space="preserve">$text</w:t></w:r></w:p></w:tc>');
    }
    rowXml.write('</w:tr>');
    return XmlDocument.parse(rowXml.toString()).rootElement.copy();
  }

  static String _escapeXmlText(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _getRowText(XmlElement tr) {
    return tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
  }
}
