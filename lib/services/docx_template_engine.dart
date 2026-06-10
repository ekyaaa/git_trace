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
    final allTElements = doc.findAllElements('t', namespace: _nsW).toList();
    for (final tElement in allTElements) {
      _replaceInTextNode(tElement, variables);
    }
  }

  static void _replaceInTextNode(XmlElement tElement, Map<String, String> variables) {
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

  static void _replaceInClonedRow(XmlElement row, ReportRowModel rowData) {
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

  static String _getRowText(XmlElement tr) {
    return tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
  }

  static XmlElement _cloneRow(XmlElement original) {
    final xmlString = original.toXmlString();
    return XmlDocument.parse(xmlString).rootElement.copy();
  }
}
