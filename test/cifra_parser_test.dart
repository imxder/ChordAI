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

  test('lê Capo e Batida do cabeçalho da cifra', () {
    const raw = '''
Tom: C
Capo: 2
Batida: D D U U D U

[Intro]
   C
Primeira linha
''';

    final sheet = parseCifra(raw, title: 'Teste');

    expect(sheet.capo, 2);
    expect(sheet.strummingPattern, ['D', 'D', 'U', 'U', 'D', 'U']);
  });

  test('capo e batida são nulos quando não informados', () {
    const raw = '''
Tom:  C

[Intro]
   C
Primeira linha
''';

    final sheet = parseCifra(raw, title: 'Teste');

    expect(sheet.capo, isNull);
    expect(sheet.strummingPattern, isNull);
  });
}
