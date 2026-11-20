import 'dart:io';
import 'dart:math';

import 'package:chordai/models/tuner_note.dart';
import 'package:chordai/services/pitch_detector.dart';
import 'package:chordai/services/pitch_smoother.dart';
import 'package:chordai/services/tuner_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wav_fixture.dart';

const _windowSize = 4096;
const _hopSize = 1024;

/// O que a tela mostraria a cada salto: a corda (ou `null`, sem ponteiro) e o
/// tempo em segundos. Faz o mesmo caminho do TunerService: janela de 4096
/// amostras andando 1024 por vez, nível das amostras novas, YIN, PitchSmoother
/// e a corda mais próxima na afinação padrão.
List<(double, String?)> _tela(List<double> samples, double sampleRate) {
  var now = DateTime(2000);
  final hop = Duration(microseconds: (_hopSize * 1e6 / sampleRate).round());
  final smoother = PitchSmoother(clock: () => now);
  final out = <(double, String?)>[];
  for (
    var start = 0;
    start + _windowSize <= samples.length;
    start += _hopSize
  ) {
    final window = samples.sublist(start, start + _windowSize);
    final frequency = smoother.update(
      detectPitchWithConfidence(window, sampleRate),
      level: TunerService.newSamplesLevel(window),
    );
    now = now.add(hop);
    out.add((
      (start + _windowSize) / sampleRate,
      classifyPitch(frequency, guitarStrings)?.nearestString.name,
    ));
  }
  return out;
}

/// As cordas na ordem em que apareceram na tela, sem repetir seguidas.
List<String> _sequencia(List<(double, String?)> tela) {
  final seq = <String>[];
  for (final (_, corda) in tela) {
    if (corda != null && (seq.isEmpty || seq.last != corda)) seq.add(corda);
  }
  return seq;
}

void main() {
  final e2 = File('test/fixtures/strings/E2.wav');
  final a2 = File('test/fixtures/strings/A2.wav');
  final semGravacoes = !e2.existsSync() || !a2.existsSync();

  test('Lá tocada por cima do Mi ainda soando troca de E2 pra A2, sem passar por outra', () {
    final mi = readWav(e2);
    final la = readWav(a2);
    expect(la.sampleRate, mi.sampleRate);
    // O Mi soa sozinho por 2 s e a Lá entra por cima, com o Mi continuando.
    final inicioLa = (2.0 * mi.sampleRate).round();
    final total = max(mi.samples.length, inicioLa + la.samples.length);
    final mix = List<double>.generate(total, (i) {
      final m = i < mi.samples.length ? mi.samples[i] : 0.0;
      final l = i >= inicioLa && i - inicioLa < la.samples.length
          ? la.samples[i - inicioLa]
          : 0.0;
      return (m + l).clamp(-1.0, 1.0);
    });

    final tela = _tela(mix, mi.sampleRate);
    expect(_sequencia(tela), ['E2', 'A2']);
    expect(tela.last.$2, 'A2');
  }, skip: semGravacoes ? 'sem as gravações E2.wav e A2.wav' : false);

  test(
    'Mi morrendo até o silêncio: o ponteiro fica no E2 e só some depois de 3 s',
    () {
      final mi = readWav(e2);
      final sr = mi.sampleRate;
      // A gravação acaba com a corda ainda soando: aqui ela vai sumindo em
      // 1,5 s e depois vêm 5 s de silêncio.
      final fade = (1.5 * sr).round();
      final samples = [
        ...mi.samples,
        for (var i = 0; i < fade; i++)
          mi.samples[mi.samples.length - fade + i] * (1 - i / fade),
        ...List<double>.filled((5 * sr).round(), 0.0),
      ];
      final fimDoSom = (mi.samples.length + fade) / sr;

      final tela = _tela(samples, sr);
      expect(_sequencia(tela), ['E2']);

      final ultimo = tela.lastWhere((t) => t.$2 != null).$1;
      expect(
        ultimo,
        greaterThan(fimDoSom + 1.0),
        reason: 'o ponteiro continua parado depois que o som acaba',
      );
      expect(tela.last.$2, isNull, reason: 'mais de 3 s de silêncio');
    },
    skip: semGravacoes ? 'sem a gravação E2.wav' : false,
  );
}
