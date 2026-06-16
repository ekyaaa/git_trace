import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() async {
  final file = File('assets/templates/default_logbook_template.docx');
  final templateBytes = file.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(templateBytes);

  String? rawXml;
  for (final f in archive.files) {
    if (f.name == "word/document.xml") {
      rawXml = utf8.decode(f.content as List<int>);
    }
  }

  final doc = XmlDocument.parse(rawXml!);
  final allTr = doc.findAllElements('tr', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').toList();

  final _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  for (final tr in allTr) {
    final rowText = tr.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 't')
        .map((t) => t.innerText)
        .join('');
    
    if (rowText.contains('{{kegiatan}}')) {
      final cells = tr.findAllElements('tc', namespace: _nsW).toList();
      for (final cell in cells) {
        final cellText = cell.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((t) => t.innerText)
            .join('');
        if (cellText.contains('{{kegiatan}}')) {
          print('Found cell with {{kegiatan}}');
          final pElements = cell.findAllElements('p', namespace: _nsW).toList();
          print('Paragraph count: ${pElements.length}');
          for (final p in pElements) {
            print('p name: ${p.name}');
            var pPr = p.getElement('pPr', namespace: _nsW);
            print('pPr found: ${pPr != null}');
            if (pPr != null) {
              var jc = pPr.getElement('jc', namespace: _nsW);
              print('jc found: ${jc != null}');
              if (jc != null) {
                print('jc original val: ${jc.getAttribute('w:val')}');
                jc.setAttribute('w:val', 'left');
                print('jc updated val: ${jc.getAttribute('w:val')}');
              }
            }
          }
        }
      }
    }
  }
}
