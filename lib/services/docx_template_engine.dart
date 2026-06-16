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

    if (tableRows.isNotEmpty) {
      rawXmlString = _replaceTableRowsInRawXml(rawXmlString, tableRows);
    }

    rawXmlString = _replaceVariablesInRawXml(rawXmlString, variables);

    rawXmlString = _keepSignatureTableTogether(rawXmlString);

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
        result = result.replaceAll(placeholder, entry.value);
        totalReplacements++;
        print('[DocxEngine]   REPLACE "$placeholder" -> "${entry.value.length > 40 ? entry.value.substring(0, 40) + "..." : entry.value}"');
      }
    }

    print('[DocxEngine] Replaced $totalReplacements variable groups');

    final remaining = RegExp(r'\{\{.*?\}\}').allMatches(result).map((m) => m.group(0)).toSet();
    if (remaining.isNotEmpty) {
      print('[DocxEngine] Remaining after raw replace: $remaining');
      result = _replaceSplitPlaceholdersInRawXml(result, variables);
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

    final modifiedTableXml = activityTable.toXmlString(pretty: false);

    final origTableStart = rawXml.indexOf('<w:tbl>', rawXml.indexOf('<w:tbl>') + 1);
    final origTableEnd = rawXml.indexOf('</w:tbl>', origTableStart) + 8;

    if (origTableStart < 0 || origTableEnd <= 8) {
      print('[DocxEngine] WARNING: Could not find second table boundaries in raw XML, falling back to full serialization');
      final serialized = doc.toXmlString(pretty: false);
      final originalDeclEnd = rawXml.indexOf('?>');
      final serializedDeclEnd = serialized.indexOf('?>');
      if (originalDeclEnd > 0 && serializedDeclEnd > 0) {
        return rawXml.substring(0, originalDeclEnd + 2) + serialized.substring(serializedDeclEnd + 2);
      }
      return serialized;
    }

    final result = rawXml.substring(0, origTableStart) + modifiedTableXml + rawXml.substring(origTableEnd);
    print('[DocxEngine] Table splice: replaced ${origTableEnd - origTableStart} chars with ${modifiedTableXml.length} chars');
    return result;
  }

  static List<XmlElement> _findDescendantElements(XmlNode node, String localName) {
    return node.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == localName)
        .toList();
  }

  static XmlElement? _findChildElement(XmlElement element, String localName) {
    for (final child in element.children) {
      if (child is XmlElement && child.name.local == localName) {
        return child;
      }
    }
    return null;
  }

  static XmlElement _buildRowFromTemplate(XmlElement templateRow, ReportRowModel rowData) {
    final newRow = templateRow.copy();

    // Align paragraph for kegiatan to left using namespace-independent helper
    final cells = _findDescendantElements(newRow, 'tc');
    for (final cell in cells) {
      final cellText = cell.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 't')
          .map((t) => t.innerText)
          .join('');
      if (cellText.contains('{{kegiatan}}')) {
        final pElements = _findDescendantElements(cell, 'p');
        for (final p in pElements) {
          var pPr = _findChildElement(p, 'pPr');
          if (pPr == null) {
            final pPrFragment = XmlDocument.parse('<w:pPr xmlns:w="$_nsW"/>');
            pPr = pPrFragment.rootElement.copy();
            p.children.insert(0, pPr);
          }
          var jc = _findChildElement(pPr, 'jc');
          if (jc != null) {
            jc.setAttribute('w:val', 'left');
          } else {
            final jcFragment = XmlDocument.parse('<w:jc w:val="left" xmlns:w="$_nsW"/>');
            pPr.children.add(jcFragment.rootElement.copy());
          }
        }
      }
    }

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
        if (newText.contains('\n')) {
          final parent = tElement.parent;
          if (parent != null) {
            final lines = newText.split('\n');
            final newChildren = <XmlNode>[];
            for (int i = 0; i < lines.length; i++) {
              if (i > 0) {
                final brFragment = XmlDocument.parse('<w:br xmlns:w="$_nsW"/>');
                newChildren.add(brFragment.rootElement.copy());
              }
              final escapedLine = _escapeXmlText(lines[i]);
              final tFragment = XmlDocument.parse('<w:t xml:space="preserve" xmlns:w="$_nsW">$escapedLine</w:t>');
              newChildren.add(tFragment.rootElement.copy());
            }
            final index = parent.children.indexOf(tElement);
            if (index >= 0) {
              parent.children.removeAt(index);
              parent.children.insertAll(index, newChildren);
            }
          } else {
            tElement.innerText = newText;
          }
        } else {
          tElement.innerText = newText;
        }
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
      rowXml.write('<w:tc>');
      final isKegiatan = (i == 3);
      final pPr = isKegiatan ? '<w:pPr><w:jc w:val="left"/></w:pPr>' : '';
      rowXml.write('<w:p>$pPr<w:r>');
      if (i < positionalValues.length) {
        final text = positionalValues[i];
        final lines = text.split('\n');
        for (int j = 0; j < lines.length; j++) {
          if (j > 0) {
            rowXml.write('<w:br/>');
          }
          rowXml.write('<w:t xml:space="preserve">${_escapeXmlText(lines[j])}</w:t>');
        }
      }
      rowXml.write('</w:r></w:p></w:tc>');
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

  static void _applyKeepNextToParagraph(XmlElement p) {
    var pPr = _findChildElement(p, 'pPr');
    if (pPr == null) {
      final pPrFragment = XmlDocument.parse('<w:pPr xmlns:w="$_nsW"/>');
      pPr = pPrFragment.rootElement.copy();
      p.children.insert(0, pPr);
    }
    final existingKeepNext = _findChildElement(pPr, 'keepNext');
    if (existingKeepNext == null) {
      final keepNextFragment = XmlDocument.parse('<w:keepNext xmlns:w="$_nsW"/>');
      pPr.children.add(keepNextFragment.rootElement.copy());
    }
  }

  static void _applyCantSplitToRow(XmlElement tr) {
    var trPr = _findChildElement(tr, 'trPr');
    if (trPr == null) {
      final trPrFragment = XmlDocument.parse('<w:trPr xmlns:w="$_nsW"/>');
      trPr = trPrFragment.rootElement.copy();
      tr.children.insert(0, trPr);
    }
    final existingCantSplit = _findChildElement(trPr, 'cantSplit');
    if (existingCantSplit != null) {
      trPr.children.remove(existingCantSplit);
    }
    final cantSplitFragment = XmlDocument.parse('<w:cantSplit xmlns:w="$_nsW"/>');
    trPr.children.add(cantSplitFragment.rootElement.copy());
  }

  static String _keepSignatureTableTogether(String rawXml) {
    try {
      final doc = XmlDocument.parse(rawXml);
      
      // Find body element
      final body = doc.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.name.local == 'body', orElse: () => throw Exception('body not found'));
      final children = body.children.whereType<XmlElement>().toList();
      
      // Find activity table index (second table or table containing "kegiatan")
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
      
      // Find start of signature section after activity table
      int signatureStartIdx = -1;
      if (activityTableIdx != -1) {
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
      }
      
      if (signatureStartIdx != -1) {
        print('[DocxEngine] Chaining signature section starting at element $signatureStartIdx');
        for (int i = signatureStartIdx; i < children.length; i++) {
          final element = children[i];
          if (element.name.local == 'p') {
            _applyKeepNextToParagraph(element);
          } else if (element.name.local == 'tbl') {
            // Apply cantSplit to rows
            final rows = _findDescendantElements(element, 'tr');
            for (final tr in rows) {
              _applyCantSplitToRow(tr);
            }
            // Apply keepNext to cell paragraphs
            final pElements = _findDescendantElements(element, 'p');
            for (final p in pElements) {
              _applyKeepNextToParagraph(p);
            }
          }
        }
      } else {
        // Fallback: old behavior of targeting only the last signature table
        print('[DocxEngine] Warning: no signature start paragraph found. Using fallback.');
        final allTables = doc.findAllElements('tbl', namespace: _nsW).toList();
        if (allTables.isNotEmpty) {
          XmlElement? signatureTable;
          for (final tbl in allTables) {
            final text = tbl.descendants
                .whereType<XmlElement>()
                .where((e) => e.name.local == 't')
                .map((t) => t.innerText)
                .join(' ');
            if (text.contains('Mahasiswa') || text.contains('Pembimbing')) {
              signatureTable = tbl;
            }
          }
          signatureTable ??= allTables.last;
          
          final rows = _findDescendantElements(signatureTable, 'tr');
          for (final tr in rows) {
            _applyCantSplitToRow(tr);
          }
          final pElements = _findDescendantElements(signatureTable, 'p');
          for (final p in pElements) {
            _applyKeepNextToParagraph(p);
          }
        }
      }
      
      return doc.toXmlString(pretty: false);
    } catch (e) {
      print('[DocxEngine] Error keeping signature table together: $e');
      return rawXml;
    }
  }
}
