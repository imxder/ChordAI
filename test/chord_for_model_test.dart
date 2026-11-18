import 'package:chordai/models/chord_for_model.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _v3 = {'Am', 'Bb', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'};
const _v3Meu = {..._v3, 'A'};

void main() {
  test('acorde que o modelo conhece fica igual', () {
    for (final c in _v3) {
      expect(chordForModel(c, _v3), c);
    }
  });

  test('tira o baixo', () {
    expect(chordForModel('C/G', _v3), 'C');
    expect(chordForModel('Am/E', _v3), 'Am');
    expect(chordForModel('G/B', _v3), 'G');
  });

  test('reduz extensões ao acorde básico', () {
    expect(chordForModel('Am7', _v3), 'Am');
    expect(chordForModel('G7', _v3), 'G');
    expect(chordForModel('Cmaj7', _v3), 'C');
    expect(chordForModel('Fmaj7', _v3), 'F');
    expect(chordForModel('C7M', _v3), 'C');
    expect(chordForModel('Cadd9', _v3), 'C');
    expect(chordForModel('Em7(9)', _v3), 'Em');
    expect(chordForModel('G6', _v3), 'G');
  });

  test('troca a enarmonia pelo nome que o modelo conhece', () {
    expect(chordForModel('A#', _v3), 'Bb');
    expect(chordForModel('A#m', {'Bbm'}), 'Bbm');
  });

  test('diminuto só se o modelo tiver', () {
    expect(chordForModel('Bdim', _v3), 'Bdim');
    expect(chordForModel('B°', _v3), 'Bdim');
    expect(chordForModel('Bm7(b5)', _v3), 'Bdim');
    expect(chordForModel('C#dim', _v3), isNull);
  });

  test('sus, aumentado e power chord não contam', () {
    expect(chordForModel('Csus4', _v3), isNull);
    expect(chordForModel('Dsus2', _v3), isNull);
    expect(chordForModel('Caug', _v3), isNull);
    expect(chordForModel('C+', _v3), isNull);
    expect(chordForModel('E5', _v3), isNull);
  });

  test('acorde que o modelo não conhece e o que não é acorde viram null', () {
    expect(chordForModel('D', _v3), isNull);
    expect(chordForModel('E', _v3), isNull);
    expect(chordForModel('A', _v3), isNull);
    expect(chordForModel('A', _v3Meu), 'A');
    expect(chordForModel('A7', _v3Meu), 'A');
    expect(chordForModel('x', _v3), isNull);
    expect(chordForModel('', _v3), isNull);
  });

  test('linha com C/G, Am7 e G7 agora é lida como linha de acordes', () {
    final cifra = parseCifra('C/G  Am7  G7\nletra da música\n', title: 'x');
    expect(cifra.sections.first.lines.first.chordLine, 'C/G  Am7  G7');
    expect(cifra.sections.first.lines.first.lyricText, 'letra da música');
  });

  test('palavras comuns da letra continuam sendo letra', () {
    final cifra = parseCifra('Bom dia\nCada acorde fica\n', title: 'x');
    expect(
      cifra.sections.first.lines.every((l) => l.chordLine == null),
      isTrue,
    );
  });
}
