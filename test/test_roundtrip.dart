import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);
  
  XmlDocument? docXml;
  for (final file in archive.files) {
    if (file.name == 'word/document.xml') {
      final xmlStr = utf8.decode(file.content as List<int>);
      docXml = XmlDocument.parse(xmlStr);
      break;
    }
  }
  
  if (docXml == null) {
    print('ERROR: document.xml not found');
    return;
  }
  
  final reSerialized = docXml.toXmlString(pretty: false);
  
  final origFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
  final origContent = utf8.decode(origFile.content as List<int>);
  
  print('Original length: ${origContent.length}');
  print('Re-serialized length: ${reSerialized.length}');
  print('Are they identical: ${origContent == reSerialized}');
  
  if (origContent != reSerialized) {
    for (int i = 0; i < origContent.length && i < reSerialized.length; i++) {
      if (origContent[i] != reSerialized[i]) {
        final start = i > 80 ? i - 80 : 0;
        final end = i + 200 < reSerialized.length ? i + 200 : reSerialized.length;
        final endO = i + 200 < origContent.length ? i + 200 : origContent.length;
        print('First diff at position $i:');
        print('  Original: ...${origContent.substring(start, endO)}...');
        print('  Re-serial: ...${reSerialized.substring(start, end)}...');
        break;
      }
    }
  }
}
