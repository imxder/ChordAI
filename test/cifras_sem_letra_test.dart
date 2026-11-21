import 'dart:io';

import 'package:chordai/services/cifra_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// As letras têm direito autoral: as cifras que vêm com o app só têm as partes
// da música e os acordes. Se alguém colar uma letra de volta, este teste quebra.
void main() {
  final arquivos = Directory('assets/lyrics')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.txt'))
      .toList();

  test('tem cifra para testar', () {
    expect(arquivos, isNotEmpty);
  });

  for (final arquivo in arquivos) {
    test('${arquivo.uri.pathSegments.last} não tem letra', () {
      final cifra = parseCifra(arquivo.readAsStringSync(), title: 'teste');
      final linhas = [for (final s in cifra.sections) ...s.lines];
      expect(linhas.where((l) => l.chordLine != null), isNotEmpty);
      for (final linha in linhas) {
        expect(linha.lyricText, isEmpty, reason: linha.lyricText);
      }
    });
  }
}
