import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() {
  try {
    final file = File('assets/templates/default_logbook_template.docx');
    print('File exists: ${file.existsSync()}');
    final bytes = file.readAsBytesSync();
    print('Bytes read: ${bytes.length}');
    final archive = ZipDecoder().decodeBytes(bytes);
    print('Archive files count: ${archive.files.length}');
    
    final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
    print('Found word/document.xml size: ${docFile.content.length}');
    
    final content = utf8.decode(docFile.content as List<int>);
    print('Decoded content length: ${content.length}');
    
    final doc = XmlDocument.parse(content);
    // Find tbl elements with any namespace
    final tables = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tbl').toList();
    print('Found tables count (localName): ${tables.length}');
    
    for (var i = 0; i < tables.length; i++) {
      final text = tables[i].descendants.whereType<XmlElement>().where((e) => e.name.local == 't').map((t) => t.innerText).join(' ');
      print('Table $i (localName) contains: $text');
    }
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
