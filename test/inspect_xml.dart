import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  String? rawXml;
  for (final file in archive.files) {
    if (file.name == "word/document.xml") {
      rawXml = utf8.decode(file.content as List<int>);
    }
  }

  if (rawXml == null) {
    print("ERROR: word/document.xml not found");
    return;
  }

  final doc = XmlDocument.parse(rawXml);
  final allTr = doc.findAllElements('tr', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
  
  print('Total rows found: ${allTr.length}');
  for (int i = 0; i < allTr.length; i++) {
    final tr = allTr[i];
    final rowText = tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
    
    if (rowText.contains('{{kegiatan}}')) {
      print('Row $i text: $rowText');
      print('Row $i XML structure of the {{kegiatan}} cell:');
      
      final cells = tr.findAllElements('tc', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
      for (final cell in cells) {
        final cellText = cell.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((t) => t.innerText)
            .join('');
        if (cellText.contains('{{kegiatan}}')) {
          print(cell.toXmlString(pretty: true));
        }
      }
    }
  }
}
