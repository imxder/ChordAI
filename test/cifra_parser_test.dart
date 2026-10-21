import 'package:chordai/services/cifra_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê Tom e Tempo do cabeçalho da cifra', () {
    const raw = '''
Tom:  C
Tempo: 98

[Intro]
   C
Primeira linha
''';

    final sheet = parseCifra(raw, title: 'Teste');

    expect(sheet.key, 'C');
    expect(sheet.tempo, 98);
  });

  test('funciona sem Tempo informado', () {
    const raw = '''
Tom:  C

[Intro]
   C
Primeira linha
''';

    final sheet = parseCifra(raw, title: 'Teste');

    expect(sheet.key, 'C');
    expect(sheet.tempo, isNull);
  });
}
