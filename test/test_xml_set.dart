import 'package:xml/xml.dart';

void main() {
  final doc = XmlDocument.parse('<w:jc w:val="center" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"/>');
  final jc = doc.rootElement;
  print('Original attributes:');
  for (final attr in jc.attributes) {
    print('  - Name: "${attr.name}", Value: "${attr.value}"');
  }

  // 1. Literal setAttribute('w:val')
  jc.setAttribute('w:val', 'left');
  print('\nAfter setAttribute(\'w:val\', \'left\'):');
  for (final attr in jc.attributes) {
    print('  - Name: "${attr.name}", Value: "${attr.value}"');
  }

  // 2. Namespace-aware setAttribute
  jc.setAttribute('val', 'left', namespace: 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
  print('\nAfter setAttribute(\'val\', \'left\', namespace: ...):');
  for (final attr in jc.attributes) {
    print('  - Name: "${attr.name}", Value: "${attr.value}"');
  }
}
