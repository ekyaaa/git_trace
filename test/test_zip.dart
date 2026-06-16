import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);
  
  // Replicate engine behavior exactly
  final newArchive = Archive();
  XmlDocument? documentXml;
  
  for (int i = 0; i < archive.files.length; i++) {
    final file = archive.files[i];
    if (file.name == 'word/document.xml') {
      final xmlString = utf8.decode(file.content as List<int>);
      documentXml = XmlDocument.parse(xmlString);
    } else {
      newArchive.addFile(file);
    }
  }
  
  if (documentXml == null) {
    print('ERROR: document.xml not found');
    return;
  }
  
  final finalXml = documentXml.toXmlString(pretty: false);
  final newDocBytes = Uint8List.fromList(utf8.encode(finalXml));
  newArchive.addFile(ArchiveFile('word/document.xml', newDocBytes.length, newDocBytes));
  
  final encoded = ZipEncoder().encode(newArchive);
  if (encoded == null) {
    print('ERROR: Failed to encode');
    return;
  }
  
  await File('/tmp/test_engine_output.docx').writeAsBytes(encoded);
  
  print('Output written to /tmp/test_engine_output.docx');
  print('Size: ${encoded.length} bytes');
  
  // Verify by re-reading
  final verify = ZipDecoder().decodeBytes(encoded);
  final docFile = verify.files.firstWhere((f) => f.name == 'word/document.xml');
  final docContent = utf8.decode(docFile.content as List<int>);
  
  // Check placeholders
  final hasMahasiswa = docContent.contains('{{nama_mahasiswa}}');
  final hasPembimbing = docContent.contains('{{nama_pembimbing}}');
  final hasPlapangan = docContent.contains('{{nama_pembimbing_lapangan}}');
  
  print('Has {{nama_mahasiswa}}: $hasMahasiswa');
  print('Has {{nama_pembimbing}}: $hasPembimbing');
  print('Has {{nama_pembimbing_lapangan}}: $hasPlapangan');
  
  // Check XML validity
  try {
    XmlDocument.parse(docContent);
    print('Output XML is VALID');
  } catch (e) {
    print('Output XML is INVALID: $e');
  }
}
