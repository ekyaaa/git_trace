import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final file = File('assets/templates/default_logbook_template.docx');
  if (!file.existsSync()) {
    print('Error: assets/templates/default_logbook_template.docx not found');
    return;
  }
  
  final templateBytes = file.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  String? rawXml;
  for (final f in archive.files) {
    if (f.name == "word/document.xml") {
      rawXml = utf8.decode(f.content as List<int>);
    }
  }

  if (rawXml == null) {
    print("Error: word/document.xml not found");
    return;
  }

  final doc = XmlDocument.parse(rawXml);
  final tables = doc.findAllElements('tbl', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
  print('Total tables: ${tables.length}');

  for (int i = 0; i < tables.length; i++) {
    final tableText = tables[i].descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join(' ');
    
    if (tableText.contains('Mahasiswa') || tableText.contains('Dosen Pembimbing')) {
      print('=== Table $i (Signature Table) ===');
      print(tables[i].toXmlString(pretty: true));
    }
  }
}
