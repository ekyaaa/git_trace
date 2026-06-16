import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final file = File('/tmp/test_export_flow.docx');
  if (!file.existsSync()) {
    print('ERROR: /tmp/test_export_flow.docx does not exist. Please run test_full_export_flow first.');
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
    print("ERROR: word/document.xml not found");
    return;
  }

  final doc = XmlDocument.parse(rawXml);
  final allTr = doc.findAllElements('tr', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
  
  print('Total rows in output: ${allTr.length}');
  for (int i = 0; i < allTr.length; i++) {
    final tr = allTr[i];
    final rowText = tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
    
    if (rowText.contains('Meeting')) {
      print('Row $i text: $rowText');
      
      final cells = tr.findAllElements('tc', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();
      for (final cell in cells) {
        final cellText = cell.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((t) => t.innerText)
            .join('');
        if (cellText.contains('Meeting')) {
          print(cell.toXmlString(pretty: true));
        }
      }
    }
  }
}
