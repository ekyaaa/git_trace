import 'package:xml/xml.dart';

void main() {
  final raw = '<w:tr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:tc><w:p><w:t>Hello</w:t></w:p></w:tc></w:tr>';
  final doc = XmlDocument.parse(raw);
  final tr = doc.rootElement;

  print('1. Original tr search:');
  print('   - findAllElements(\'tc\', namespace: ...): ${tr.findAllElements('tc', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').length}');
  print('   - findAllElements(\'tc\'): ${tr.findAllElements('tc').length}');
  print('   - children names: ${tr.children.map((c) => c is XmlElement ? c.name : c.toString())}');

  // Detach/copy tr
  final copiedTr = tr.copy();
  print('\n2. Copied/detached tr search:');
  print('   - findAllElements(\'tc\', namespace: ...): ${copiedTr.findAllElements('tc', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').length}');
  print('   - findAllElements(\'tc\'): ${copiedTr.findAllElements('tc').length}');
  print('   - children names: ${copiedTr.children.map((c) => c is XmlElement ? c.name : c.toString())}');
  
  // Try searching using wildcard namespace or name.local comparison
  print('\n3. Searching descendants manually by name.local:');
  final manualSearch = copiedTr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tc').toList();
  print('   - Manual search length: ${manualSearch.length}');
}
