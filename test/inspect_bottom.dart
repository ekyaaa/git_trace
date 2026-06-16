import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() {
  final bytes = File('assets/templates/default_logbook_template.docx').readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final content = utf8.decode(archive.firstWhere((f) => f.name == 'word/document.xml').content);
  final doc = XmlDocument.parse(content);
  
  final body = doc.descendants.whereType<XmlElement>().firstWhere((e) => e.name.local == 'body');
  final children = body.children.whereType<XmlElement>().toList();
  
  int tbl1Index = -1;
  int tblCount = 0;
  for (int i = 0; i < children.length; i++) {
    if (children[i].name.local == 'tbl') {
      tblCount++;
      if (tblCount == 2) { // Table 1 (0-indexed) is the second table
        tbl1Index = i;
      }
    }
  }
  
  print('Table 1 index: $tbl1Index');
  if (tbl1Index == -1) return;
  
  print('=== Elements after Table 1 ===');
  for (int i = tbl1Index + 1; i < children.length; i++) {
    final child = children[i];
    final text = child.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
    print('Element $i: <w:${child.name.local}> text="${text.trim()}"');
  }
}
