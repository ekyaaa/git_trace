import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:git_trace/models/report_row_model.dart';
import 'package:git_trace/services/docx_template_engine.dart';

void main() async {
  final templateBytes = await File('assets/templates/default_logbook_template.docx').readAsBytes();

  final tableRows = [
    ReportRowModel(dayDate: "Senin, 02/06/2026", checkIn: "08:00", checkOut: "17:00", kegiatan: "Pengembangan fitur export"),
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

  await File("/tmp/test_new_layout.docx").writeAsBytes(output);
  print("\nOutput: ${output.length} bytes");

  // Verify output
  final archive2 = ZipDecoder().decodeBytes(output);
  final docBytes = archive2.files.firstWhere((f) => f.name == "word/document.xml").content as List<int>;
  final docXml = utf8.decode(docBytes);

  print("Has Mahasiswa,: ${docXml.contains("Mahasiswa,")}");
  print("Has Mengetahui,: ${docXml.contains("Mengetahui,")}");
  print("Has Dosen Pembimbing,: ${docXml.contains("Dosen Pembimbing,")}");
  print("Has Pembimbing Lapangan,: ${docXml.contains("Pembimbing Lapangan,")}");
  print("Has Alex: ${docXml.contains("Alex")}");
  print("Has Dr. Budi: ${docXml.contains("Dr. Budi Santoso")}");
  print("Has Ir. Siti: ${docXml.contains("Ir. Siti Aminah")}");

  final remaining = RegExp(r"\{\{.*?\}\}").allMatches(docXml).map((m) => m.group(0)).toSet();
  print("Remaining placeholders: ${remaining.isEmpty ? "NONE" : remaining}");
}
