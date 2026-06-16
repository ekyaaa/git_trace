import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() {
  final bytes = File('assets/templates/default_logbook_template.docx').readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final content = utf8.decode(archive.firstWhere((f) => f.name == 'word/document.xml').content);
  final doc = XmlDocument.parse(content);
  
  final tElements = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').toList();
  for (final t in tElements) {
    if (t.innerText.contains('Mahasiswa')) {
      print('Found "Mahasiswa" in element:');
      print(t.toXmlString(pretty: true));
      
      // Let's print parent elements up to the table or body
      var current = t.parent;
      int depth = 1;
      while (current != null) {
        if (current is XmlElement) {
          print('Parent level $depth: <w:${current.name.local}> properties: ${current.attributes}');
          if (current.name.local == 'tbl' || current.name.local == 'body') {
            break;
          }
        }
        current = current.parent;
        depth++;
      }
      print('-----------------------------------------');
    }
  }
}
