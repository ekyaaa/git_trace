import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:git_trace/models/report_row_model.dart';
import 'package:git_trace/services/docx_template_engine.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();

  final tableRows = [
    ReportRowModel(dayDate: "Senin, 02/06/2026", checkIn: "08:00", checkOut: "17:00", kegiatan: "Pengembangan fitur export"),
    ReportRowModel(dayDate: "Selasa, 03/06/2026", checkIn: "08:00", checkOut: "17:00", kegiatan: "Testing aplikasi"),
  ];

  final variables = <String, String>{
    "nama": "Alex", "nim": "41821001", "prodi": "Teknik Informatika",
    "mitra": "PT Telkom", "pembimbing": "Dr. Budi", "pembimbing_lapangan": "Ir. Siti",
    "nama_mahasiswa": "Alex", "nama_pembimbing": "Dr. Budi Santoso, M.Kom",
    "nama_pembimbing_lapangan": "Ir. Siti Aminah, M.T", "bulan": "06", "tahun": "2026",
  };

  final output = await DocxTemplateEngine.generate(
    templateBytes: templateBytes,
    variables: variables,
    tableRows: tableRows,
  );

  await File("/tmp/test_full_new_engine.docx").writeAsBytes(output);
  print("\nOutput written: ${output.length} bytes");

  // Verify output
  final archive2 = ZipDecoder().decodeBytes(output);
  final docBytes = archive2.files.firstWhere((f) => f.name == "word/document.xml").content as List<int>;
  final docXml = utf8.decode(docBytes);

  print("XML declaration preserved: ${docXml.startsWith("<?xml")}");
  print("Has xmlns:w: ${docXml.contains("xmlns:w=")}");
  print("Has ve:Ignorable: ${docXml.contains("ve:Ignorable")}");
  print("Has Mahasiswa,: ${docXml.contains("Mahasiswa,")}");
  print("Has Mengetahui,: ${docXml.contains("Mengetahui,")}");
  print("Has Dosen Pembimbing,: ${docXml.contains("Dosen Pembimbing,")}");
  print("Has Pembimbing Lapangan,: ${docXml.contains("Pembimbing Lapangan,")}");
  print("Has Alex: ${docXml.contains("Alex")}");
  print("Has Dr. Budi: ${docXml.contains("Dr. Budi Santoso, M.Kom")}");
  print("Has Ir. Siti: ${docXml.contains("Ir. Siti Aminah, M.T")}");

  // Check table rows
  print("Has Senin: ${docXml.contains("Senin, 02/06/2026")}");
  print("Has Selasa: ${docXml.contains("Selasa, 03/06/2026")}");
  print("Has Pengembangan: ${docXml.contains("Pengembangan fitur export")}");

  // Remaining placeholders
  final remaining = RegExp(r"\{\{.*?\}\}").allMatches(docXml).map((m) => m.group(0)).toSet();
  print("Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}");
}
