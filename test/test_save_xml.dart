import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);
  
  XmlDocument? documentXml;
  for (final file in archive.files) {
    if (file.name == 'word/document.xml') {
      documentXml = XmlDocument.parse(utf8.decode(file.content as List<int>));
    }
  }

  final originalXml = utf8.decode((archive.files.firstWhere((f) => f.name == 'word/document.xml')).content as List<int>);
  final reSerialized = documentXml!.toXmlString(pretty: false);
  
  await File('/tmp/original_doc.xml').writeAsString(originalXml);
  await File('/tmp/reserialized_doc.xml').writeAsString(reSerialized);
  
  print('Original: ${originalXml.length} chars');
  print('Re-serialized: ${reSerialized.length} chars');
  
  final origSigStart = originalXml.lastIndexOf('</w:tbl>');
  final origSectPr = originalXml.indexOf('<w:sectPr');
  final origSig = originalXml.substring(origSigStart, origSectPr);
  
  final reSigStart = reSerialized.lastIndexOf('</w:tbl>');
  final reSectPr = reSerialized.indexOf('<w:sectPr');
  final reSig = reSerialized.substring(reSigStart, reSectPr);
  
  print('\nOriginal signature section: ${origSig.length} chars');
  print('Re-serialized signature section: ${reSig.length} chars');
  
  print('\nRe-sig contains "Mahasiswa,": ${reSig.contains("Mahasiswa,")}');
  print('Re-sig contains "Mengetahui,": ${reSig.contains("Mengetahui,")}');
  print('Re-sig contains "Dosen Pembimbing,": ${reSig.contains("Dosen Pembimbing,")}');
  print('Re-sig contains "Pembimbing Lapangan,": ${reSig.contains("Pembimbing Lapangan,")}');
  print('Re-sig contains "nama_mahasiswa": ${reSig.contains("nama_mahasiswa")}');
}
