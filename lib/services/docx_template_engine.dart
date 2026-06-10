import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/report_row_model.dart';

class DocxTemplateEngine {
  static const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  /// Generates a .docx from a template by replacing {{variable}} placeholders.
  static Future<Uint8List> generate({
    required Uint8List templateBytes,
    required Map<String, String> variables,
    required List<ReportRowModel> tableRows,
  }) async {
    // 1. Unzip the .docx
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

    // 2. Handle table rows FIRST (before general variable replacement)
    //    to prevent table placeholders from being wiped by _replaceAllVariables.
    _replaceTableRows(documentXml, tableRows);

    // 3. Replace all {{variable}} placeholders in the entire document
    _replaceAllVariables(documentXml, variables);

    // 4. Add modified document.xml back
    final newDocXml = documentXml.toXmlString(pretty: false);
    final newDocBytes = Uint8List.fromList(utf8.encode(newDocXml));
    newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

    // 5. Repack
    final encoded = ZipEncoder().encode(newArchive);
    if (encoded == null) {
      throw Exception('Failed to encode docx archive');
    }
    return Uint8List.fromList(encoded);
  }

  /// Replaces all {{variable}} placeholders in all text nodes recursively.
  static void _replaceAllVariables(XmlNode node, Map<String, String> variables) {
    // Recurse into all children (XmlDocument, XmlElement, etc.)
    for (final child in node.children.toList()) {
      _replaceAllVariables(child, variables);
    }

    if (node is XmlElement && node.name.local == 't') {
      final value = node.innerText;
      if (value.contains('{{')) {
        var text = value;
        for (final entry in variables.entries) {
          final placeholder = '{{${entry.key}}}';
          if (text.contains(placeholder)) {
            text = text.replaceAll(placeholder, entry.value);
          }
        }
        // Remove empty placeholder text if not replaced
        if (text.contains('{{') && text.contains('}}')) {
          text = text.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
        }
        node.innerText = text;
      }
    }
  }

  static void _replaceTableRows(XmlDocument doc, List<ReportRowModel> tableRows) {
    final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
    if (allTables.length < 2) return;

    // The second table is the activity table
    final activityTable = allTables[1];
    final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
    if (allRows.length < 2) return;

    // Find the template row (first data row with placeholders)
    XmlElement? templateRow;
    for (int i = 1; i < allRows.length; i++) {
      final rowText = _getRowText(allRows[i]);
      if (rowText.contains('{{hari_tanggal}}') ||
          rowText.contains('{{jam_masuk}}') ||
          rowText.contains('{{jam_pulang}}') ||
          rowText.contains('{{kegiatan}}')) {
        templateRow = allRows[i];
        break;
      }
    }

    if (templateRow == null) return;

    // Remove the template row from its parent
    templateRow.parent!.children.remove(templateRow);

    // Create new rows for each data entry
    for (final rowData in tableRows) {
      final newRow = _cloneRow(templateRow);
      _replaceInRow(newRow, {
        '{{hari_tanggal}}': rowData.dayDate,
        '{{jam_masuk}}': rowData.checkIn,
        '{{jam_pulang}}': rowData.checkOut,
        '{{kegiatan}}': rowData.kegiatan,
      });
      activityTable.children.add(newRow);
    }

    // Remove remaining empty placeholder rows
    final remainingRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
    for (final row in remainingRows) {
      if (_isPlaceholderRow(row)) {
        row.parent!.children.remove(row);
      }
    }
  }

  static bool _isPlaceholderRow(XmlElement tr) {
    final rowText = _getRowText(tr);
    return rowText.trim().isEmpty ||
        rowText.contains('{{hari_tanggal}}') ||
        rowText.contains('{{jam_masuk}}') ||
        rowText.contains('{{jam_pulang}}') ||
        rowText.contains('{{kegiatan}}');
  }

  static String _getRowText(XmlElement tr) {
    // Use descendants + local name check because cloned rows may lose
    // their namespace URI when detached from the document.
    final texts = tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't');
    return texts.map((t) => t.innerText).join('');
  }

  static XmlElement _cloneRow(XmlElement original) {
    final xmlString = original.toXmlString();
    return XmlDocument.parse(xmlString).rootElement.copy();
  }

  static void _replaceInRow(XmlElement row, Map<String, String> replacements) {
    // Use descendants + local name check because cloned rows may lose
    // their namespace URI when detached from the document.
    final allTextElements = row.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't');
    for (final tElement in allTextElements) {
      var text = tElement.innerText;
      for (final entry in replacements.entries) {
        if (text.contains(entry.key)) {
          text = text.replaceAll(entry.key, entry.value);
        }
      }
      tElement.innerText = text;
    }
  }
}
