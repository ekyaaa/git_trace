import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  String? rawXml;
  for (final file in archive.files) {
    if (file.name == "word/document.xml") {
      rawXml = utf8.decode(file.content as List<int>);
    }
  }

  if (rawXml == null) { print("ERROR"); return; }

  final variables = <String, String>{
    "nama": "Alex", "nim": "Alex", "prodi": "Alex", "mitra": "Alex",
    "pembimbing": "Alex", "pembimbing_lapangan": "Alex",
    "nama_mahasiswa": "Alex", "nama_pembimbing": "Alex",
    "nama_pembimbing_lapangan": "Alex", "bulan": "06", "tahun": "2026",
  };

  var result = rawXml;
  for (final entry in variables.entries) {
    final placeholder = "{{${entry.key}}}";
    result = result.replaceAll(placeholder, entry.value);
  }

  final remaining = RegExp(r"\{\{.*?\}\}").allMatches(result).map((m) => m.group(0)).toSet();
  print("Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}");
  print("Has Mahasiswa,: ${result.contains("Mahasiswa,")}");
  print("Has Mengetahui,: ${result.contains("Mengetahui,")}");
  print("Has Dosen Pembimbing,: ${result.contains("Dosen Pembimbing,")}");
  print("Has Pembimbing Lapangan,: ${result.contains("Pembimbing Lapangan,")}");
  print("Has Alex: ${result.contains("Alex")}");
  print("XML declaration preserved: ${result.startsWith("<?xml")}");
  print("Has xmlns:w: ${result.contains("xmlns:w=")}");
  print("Has xmlns:mc: ${result.contains("xmlns:mc=")}");
  print("Has mc:Ignorable: ${result.contains("mc:Ignorable")}");

  final newArchive = Archive();
  final newDocBytes = utf8.encode(result);
  newArchive.addFile(ArchiveFile("word/document.xml", newDocBytes.length, newDocBytes));
  for (final file in archive.files) {
    if (file.name != "word/document.xml") {
      newArchive.addFile(file);
    }
  }
  final encoded = ZipEncoder().encode(newArchive);
  await File("/tmp/test_raw_string.docx").writeAsBytes(encoded!);
  print("Output: ${encoded.length} bytes");
}
