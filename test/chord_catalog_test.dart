import 'dart:convert';
import 'dart:io';

import 'package:chordai/models/chord_diagrams.dart';
import 'package:chordai/models/chord_difficulty.dart';
import 'package:chordai/models/chord_names.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final labels = (jsonDecode(
    File('assets/models/labels.json').readAsStringSync(),
  ) as List<dynamic>).cast<String>();
  final noneLabel =
      (jsonDecode(File('assets/models/model_info.json').readAsStringSync())
              as Map<String, dynamic>)['none_label']
          as String;
  final modelChords = labels.where((l) => l != noneLabel).toSet();

  test('todo acorde do modelo tem diagrama e está na lista de dificuldade', () {
    for (final chord in modelChords) {
      expect(chordFingerings, contains(chord), reason: '$chord sem diagrama');
      expect(
        chordsByDifficulty,
        contains(chord),
        reason: '$chord fora da lista',
      );
      expect(chordFullName(chord), isNot(chord), reason: '$chord sem nome');
    }
    expect(chordsByDifficulty.toSet(), modelChords);
  });

  test('diagramas têm 6 cordas, da 6ª para a 1ª', () {
    for (final entry in chordFingerings.entries) {
      expect(entry.value, hasLength(6), reason: entry.key);
    }
    expect(chordFingerings['D'], [null, null, 0, 2, 3, 2]);
    expect(chordFingerings['A'], [null, 0, 2, 2, 2, 0]);
    expect(chordFingerings['E'], [0, 2, 2, 1, 0, 0]);
  });

  test('régua de dificuldade das músicas', () {
    expect(difficultyLabel({'Em', 'E', 'Am', 'A'}), 'Fácil');
    expect(difficultyLabel({'Am', 'D'}), 'Médio');
    expect(difficultyLabel({'C', 'G', 'Dm'}), 'Médio');
    expect(difficultyLabel({'C', 'G', 'Am', 'F'}), 'Difícil');
    expect(difficultyLabel({'Bdim'}), 'Difícil');
    expect(difficultyLabel({'X'}), 'Desconhecida');
  });

  test('"Todos os acordes" em Sequências tem os acordes do modelo, na ordem do labels.json', () {
    final score = jsonDecode(
      File('assets/scores/todos_os_acordes.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final chords = [
      for (final step in score['steps'] as List<dynamic>)
        (step as Map<String, dynamic>)['chord'] as String,
    ];
    expect(chords, labels.where((l) => l != noneLabel).toList());
  });
}
