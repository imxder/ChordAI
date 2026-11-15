import 'dart:convert';
import 'dart:io';

import 'package:chordai/models/chord_diagrams.dart';
import 'package:chordai/models/chord_difficulty.dart';
import 'package:chordai/models/chord_names.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/models/on_device_model.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _modelChords(OnDeviceModel model) {
  final labels = (jsonDecode(
    File('${model.assetDir}/labels.json').readAsStringSync(),
  ) as List<dynamic>).cast<String>();
  final info = jsonDecode(
    File('${model.assetDir}/model_info.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  expect(info['output']['shape'][1], labels.length, reason: model.folder);
  return labels.where((l) => l != info['none_label']).toList();
}

void main() {
  for (final model in OnDeviceModel.values) {
    test(
      'todo acorde do modelo ${model.folder} tem diagrama, nome e está na lista',
      () {
        for (final chord in _modelChords(model)) {
          expect(
            chordFingerings,
            contains(chord),
            reason: '$chord sem diagrama',
          );
          expect(
            chordsByDifficulty,
            contains(chord),
            reason: '$chord fora da lista',
          );
          expect(chordFullName(chord), isNot(chord), reason: '$chord sem nome');
        }
      },
    );

    test('pasta ${model.folder} tem os 5 arquivos do modelo', () {
      for (final f in [
        'chord_model.tflite',
        'labels.json',
        'model_info.json',
        'example.wav',
        'example_expected.json',
      ]) {
        expect(File('${model.assetDir}/$f').existsSync(), isTrue, reason: f);
      }
    });
  }

  test('a lista de dificuldade tem todos os acordes dos dois modelos e nada a mais', () {
    final all = {for (final m in OnDeviceModel.values) ..._modelChords(m)};
    expect(chordsByDifficulty.toSet(), all);
  });

  test('o A só existe no modelo novo', () {
    expect(_modelChords(OnDeviceModel.v3), isNot(contains('A')));
    expect(_modelChords(OnDeviceModel.v3Meu), contains('A'));
    expect(chordFingerings['A'], [null, 0, 2, 2, 2, 0]);
  });

  test('diagramas têm 6 cordas', () {
    for (final entry in chordFingerings.entries) {
      expect(entry.value, hasLength(6), reason: entry.key);
    }
  });

  test('régua de dificuldade das músicas', () {
    expect(difficultyLabel({'Em', 'Am', 'A'}), 'Fácil');
    expect(difficultyLabel({'Am', 'C'}), 'Médio');
    expect(difficultyLabel({'C', 'G', 'Dm'}), 'Médio');
    expect(difficultyLabel({'C', 'G', 'Am', 'F'}), 'Difícil');
    expect(difficultyLabel({'Bdim'}), 'Difícil');
    expect(difficultyLabel({'X'}), 'Desconhecida');
  });
}
