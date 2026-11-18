import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<(String, int)> _passos(String cifra) => [
  for (final s in buildLyricPracticeMap(
    parseCifra(cifra, title: 'x'),
  ).score.steps)
    (s.chord, s.beats),
];

void main() {
  test('sem marcação, cada acorde dura 4 tempos como antes', () {
    expect(_passos('Am  G  C\nletra\n'), [('Am', 4), ('G', 4), ('C', 4)]);
  });

  test('Tempos: no topo vale pra todos os acordes', () {
    expect(_passos('Tempos: 2\nAm  G\nletra\n'), [('Am', 2), ('G', 2)]);
  });

  test('Tempos: por acorde, e o resto fica com 4', () {
    expect(_passos('Tempos: Am=2 G=2\nAm  G  C\nletra\n'), [
      ('Am', 2),
      ('G', 2),
      ('C', 4),
    ]);
  });

  test(':N na linha vale mais que o topo', () {
    expect(_passos('Tempos: Am=2 G=2\nAm:4  G:4  C  F\nletra\n'), [
      ('Am', 4),
      ('G', 4),
      ('C', 4),
      ('F', 4),
    ]);
  });

  test('o :N não aparece na tela e não desalinha os acordes', () {
    final linha = parseCifra(
      'Am:2  G   C\nletra embaixo\n',
      title: 'x',
    ).sections.first.lines.first;
    expect(linha.chordLine, 'Am    G   C');
    expect(linha.lyricText, 'letra embaixo');
    expect(linha.chordBeats, [2, null, null]);
  });

  test(
    'instrumental entre parênteses e linha depois da seção também aceitam :N',
    () {
      expect(_passos('[Intro] Am:2  G:2  C\n( F:8 )\n'), [
        ('Am', 2),
        ('G', 2),
        ('C', 4),
        ('F', 8),
      ]);
    },
  );
}
