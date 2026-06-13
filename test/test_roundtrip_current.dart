import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('/run/media/alex/DATA/Devoloper/git_trace/assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  final newArchive = Archive();
  XmlDocument? documentXml;
  for (final file in archive.files) {
    if (file.name == 'word/document.xml') {
      final xmlStr = utf8.decode(file.content as List<int>);
      documentXml = XmlDocument.parse(xmlStr);
    } else {
      newArchive.addFile(file);
    }
  }

  if (documentXml == null) { print('ERROR'); return; }
  final finalXml = documentXml.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));
  final encoded = ZipEncoder().encode(newArchive);
  await File('/tmp/current_roundtrip.docx').writeAsBytes(encoded!);
  print('Written /tmp/current_roundtrip.docx (${encoded.length} bytes)');
}
