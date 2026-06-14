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

    String? rawXmlString;

    for (int i = 0; i < archive.files.length; i++) {
      final file = archive.files[i];
      if (file.name == 'word/document.xml') {
        rawXmlString = utf8.decode(file.content as List<int>);
      } else {
        newArchive.addFile(file);
      }
    }

    if (rawXmlString == null) {
      throw Exception('word/document.xml not found in template');
    }

    print('[DocxEngine] ====== DOCX GENERATION START ======');
    print('[DocxEngine] Template bytes: ${templateBytes.length}');
    print('[DocxEngine] Archive files: ${archive.files.length}');
    print('[DocxEngine] tableRows count: ${tableRows.length}');
    print('[DocxEngine] variables: $variables');

    final requiredPlaceholders = ['{{nama}}', '{{nim}}', '{{prodi}}', '{{mitra}}', '{{pembimbing}}', '{{pembimbing_lapangan}}', '{{nama_mahasiswa}}', '{{nama_pembimbing}}', '{{nama_pembimbing_lapangan}}'];
    final foundInTemplate = <String>[];
    final missingInTemplate = <String>[];
    for (final ph in requiredPlaceholders) {
      if (rawXmlString!.contains(ph)) {
        foundInTemplate.add(ph);
      } else {
        missingInTemplate.add(ph);
      }
    }
    print('[DocxEngine] Placeholders found in template: ${foundInTemplate.length}/${requiredPlaceholders.length}');
    if (missingInTemplate.isNotEmpty) {
      print('[DocxEngine] WARNING: Missing placeholders in template: $missingInTemplate');
    }

    if (tableRows.isNotEmpty) {
      rawXmlString = _replaceTableRowsInRawXml(rawXmlString, tableRows);
    }

    rawXmlString = _replaceVariablesInRawXml(rawXmlString, variables);

    print('[DocxEngine] Final XML length: ${rawXmlString.length}');

    final remainingPlaceholders = RegExp(r'\{\{.*?\}\}').allMatches(rawXmlString).map((m) => m.group(0)).toSet();
    print('[DocxEngine] Remaining placeholders: ${remainingPlaceholders.isEmpty ? "NONE" : remainingPlaceholders}');

    final hasMahasiswa = rawXmlString.contains('Mahasiswa,');
    final hasMengetahui = rawXmlString.contains('Mengetahui,');
    final hasDosenPembimbing = rawXmlString.contains('Dosen Pembimbing,');
    final hasPembimbingLapangan = rawXmlString.contains('Pembimbing Lapangan,');
    print('[DocxEngine] Signature labels: Mahasiswa=$hasMahasiswa, Mengetahui=$hasMengetahui, DosenPembimbing=$hasDosenPembimbing, PembimbingLapangan=$hasPembimbingLapangan');

    final newDocBytes = Uint8List.fromList(utf8.encode(rawXmlString));
    newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));

    final encoded = ZipEncoder().encode(newArchive);
    if (encoded == null) {
      throw Exception('Failed to encode docx archive');
    }
    print('[DocxEngine] Output ZIP size: ${encoded.length}');
    print('[DocxEngine] ====== DOCX GENERATION END ======');
    return Uint8List.fromList(encoded);
  }

  static String _replaceVariablesInRawXml(String rawXml, Map<String, String> variables) {
    if (variables.isEmpty) return rawXml;

    var result = rawXml;
    int totalReplacements = 0;

    for (final entry in variables.entries) {
      final placeholder = '{{${entry.key}}}';
      if (result.contains(placeholder)) {
        final before = result;
        result = result.replaceAll(placeholder, entry.value);
        if (result != before) {
          totalReplacements++;
          print('[DocxEngine]   REPLACE "$placeholder" -> "${entry.value}"');
        }
      }
    }

    final remainingPlaceholders = RegExp(r'\{\{.*?\}\}').allMatches(result).map((m) => m.group(0)).toSet();
    if (remainingPlaceholders.isNotEmpty) {
      print('[DocxEngine] $totalReplacements raw replacements done, but remaining: $remainingPlaceholders');
      result = _replaceSplitPlaceholdersInRawXml(result, variables);
    } else {
      print('[DocxEngine] Replaced $totalReplacements variable groups (all via raw)');
    }

    if (result.contains('{{nama_mahasiswa}}') || result.contains('{{nama_pembimbing}}')) {
      print('[DocxEngine] WARNING: Signature placeholders still present after replacement!');
    }

    return result;
  }

  static String _replaceSplitPlaceholdersInRawXml(String rawXml, Map<String, String> variables) {
    final doc = XmlDocument.parse(rawXml);
    final allT = doc.findAllElements('t', namespace: _nsW).toList();
    int splitReplacements = 0;

    for (int i = 0; i < allT.length; i++) {
      final text = allT[i].innerText;
      if (!text.contains('{{') || text.contains('}}')) continue;

      XmlElement? blockAncestor;
      var current = allT[i];
      while (current.parent != null) {
        current = current.parent as XmlElement;
        if (current.name.local == 'p' || current.name.local == 'tc') {
          blockAncestor = current;
          break;
        }
      }
      if (blockAncestor == null) continue;

      final tInBlock = blockAncestor.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .toList();
      if (tInBlock.length <= 1) continue;

      final startIdx = tInBlock.indexOf(allT[i]);
      if (startIdx < 0) continue;

      var concatenated = '';
      final used = <XmlElement>[];
      for (int j = startIdx; j < tInBlock.length; j++) {
        concatenated += tInBlock[j].innerText;
        used.add(tInBlock[j]);
        if (concatenated.contains('}}')) break;
      }

      var replaced = concatenated;
      var didReplace = false;
      for (final entry in variables.entries) {
        final ph = '{{${entry.key}}}';
        if (replaced.contains(ph)) {
          replaced = replaced.replaceAll(ph, entry.value);
          didReplace = true;
        }
      }

      if (didReplace) {
        used.first.innerText = replaced;
        for (int k = 1; k < used.length; k++) {
          used[k].innerText = '';
        }
        splitReplacements++;
        print('[DocxEngine]   SPLIT REPLACE via ${used.length} <w:t> elements -> "${replaced.trim()}"');
      }
    }

    print('[DocxEngine] Split-placeholder replacements: $splitReplacements');
    if (splitReplacements == 0) return rawXml;
    return doc.toXmlString(pretty: false);
  }

  static String _replaceTableRowsInRawXml(String rawXml, List<ReportRowModel> tableRows) {
    final doc = XmlDocument.parse(rawXml);
    final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
    print('[DocxEngine] Tables found: ${allTables.length}');

    if (allTables.length < 2) {
      print('[DocxEngine] WARNING: Less than 2 tables, skipping row replacement');
      return rawXml;
    }

    final activityTable = allTables[1];
    final allRows = activityTable.findAllElements('tr', namespace: _nsW).toList();
    print('[DocxEngine] Activity table rows: ${allRows.length}');

    if (allRows.length < 2) return rawXml;

    XmlElement? templateRowElement;
    for (int i = 1; i < allRows.length; i++) {
      final rowText = _getRowText(allRows[i]);
      if (rowText.contains('{{')) {
        templateRowElement = allRows[i];
        print('[DocxEngine] Found template row at index $i');
        break;
      }
    }

    for (int i = allRows.length - 1; i >= 1; i--) {
      allRows[i].parent!.children.remove(allRows[i]);
    }
    print('[DocxEngine] Removed ${allRows.length - 1} non-header rows');

    if (templateRowElement != null) {
      print('[DocxEngine] Adding ${tableRows.length} rows from template');
      for (final rowData in tableRows) {
        final newRow = _buildRowFromTemplate(templateRowElement, rowData);
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

    print('[DocxEngine] Activity table modified in-place in DOM');

    return _serializeWithOriginalNamespaces(rawXml, doc);
  }

  static String _serializeWithOriginalNamespaces(String originalXml, XmlDocument doc) {
    final serialized = doc.toXmlString(pretty: false);

    final originalDeclEnd = originalXml.indexOf('?>');
    final serializedDeclEnd = serialized.indexOf('?>');

    if (originalDeclEnd > 0 && serializedDeclEnd > 0) {
      final originalDecl = originalXml.substring(0, originalDeclEnd + 2);
      final serializedAfterDecl = serialized.substring(serializedDeclEnd + 2);
      return originalDecl + serializedAfterDecl;
    }

    return serialized;
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
