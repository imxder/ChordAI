import 'dart:math';

import 'package:chordai/models/tuner_note.dart';
import 'package:chordai/services/pitch_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const sampleRate = 22050.0;
const windowSize = 4096;

List<double> _sineWave(double frequency, {double amplitude = 0.5}) {
  return List.generate(
    windowSize,
    (i) => amplitude * sin(2 * pi * frequency * i / sampleRate),
  );
}

List<double> _harmonics(double fundamental, List<double> amplitudes) {
  return List.generate(windowSize, (i) {
    var value = 0.0;
    for (var h = 0; h < amplitudes.length; h++) {
      value += amplitudes[h] * sin(2 * pi * fundamental * (h + 1) * i / sampleRate);
    }
    return value;
  });
}

double _cents(double detected, double expected) =>
    1200 * log(detected / expected) / ln2;

void main() {
  const standardTuning = {
    'E2': 82.41,
    'A2': 110.0,
    'D3': 146.83,
    'G3': 196.0,
    'B3': 246.94,
    'E4': 329.63,
  };

  test('senoides nas 6 cordas com erro abaixo de 1 cent', () {
    standardTuning.forEach((name, frequency) {
      final detected = detectPitch(_sineWave(frequency), sampleRate);
      expect(detected, isNotNull, reason: 'não detectou $name');
      expect(
        _cents(detected!, frequency).abs(),
        lessThan(1),
        reason: '$name: esperado $frequency Hz, detectou $detected Hz',
      );
    });
  });

  test('cordas da afinação do app continuam dentro de 1%', () {
    for (final string in guitarStrings) {
      final detected = detectPitch(_sineWave(string.frequency), sampleRate);
      expect(detected, isNotNull, reason: 'não detectou ${string.name}');
      expect((detected! - string.frequency).abs(), lessThan(string.frequency * 0.01));
    }
  });

  test('harmônicos pares fortes não levam a nota uma oitava acima', () {
    // Ímpares fracos fazem o sinal quase se repetir a cada meio período; sem a
    // correção em 2τ, o YIN dava 2× em E2, A2, D3 e G3.
    standardTuning.forEach((name, frequency) {
      final samples = _harmonics(frequency, [0.15, 1.0, 0.15, 0.5]);
      final detected = detectPitch(samples, sampleRate);
      expect(detected, isNotNull, reason: 'não detectou $name');
      expect(
        _cents(detected!, frequency).abs(),
        lessThan(5),
        reason: '$name: esperado $frequency Hz, detectou $detected Hz',
      );
    });
  });

  test('correção de oitava não derruba E2 para 41 Hz', () {
    for (final samples in [
      _sineWave(82.41),
      _harmonics(82.41, [0.15, 1.0, 0.15, 0.5]),
    ]) {
      // minFreq abaixo de 41 Hz deixa 2τ dentro da faixa de busca.
      final detected = detectPitch(samples, sampleRate, minFreq: 35);
      expect(detected, isNotNull);
      expect(_cents(detected!, 82.41).abs(), lessThan(5), reason: 'detectou $detected Hz');
    }
  });

  test('senoide pura de E4 continua E4', () {
    final detected = detectPitch(_sineWave(329.63), sampleRate);
    expect(detected, isNotNull);
    expect(_cents(detected!, 329.63).abs(), lessThan(1), reason: 'detectou $detected Hz');
  });

  test('confiança alta para senoide', () {
    final estimate = detectPitchWithConfidence(_sineWave(110), sampleRate);
    expect(estimate, isNotNull);
    expect(estimate!.confidence, greaterThan(0.9));
  });

  test('ruído branco retorna null', () {
    final random = Random(42);
    for (var run = 0; run < 10; run++) {
      final noise = List.generate(windowSize, (_) => random.nextDouble() - 0.5);
      expect(detectPitch(noise, sampleRate), isNull, reason: 'rodada $run');
    }
  });

  test('silêncio retorna null', () {
    expect(detectPitch(List.filled(windowSize, 0.0), sampleRate), isNull);
  });

  test('sinal abaixo do limiar de RMS retorna null', () {
    expect(detectPitch(_sineWave(110, amplitude: 0.005), sampleRate), isNull);
  });

  test('frequência fora da faixa configurada retorna null', () {
    expect(detectPitch(_sineWave(110), sampleRate, minFreq: 150), isNull);
  });

  test('tempo médio por janela de 4096 amostras', () {
    final samples = _harmonics(110, [0.15, 0.6, 0.45]);
    for (var i = 0; i < 20; i++) {
      detectPitch(samples, sampleRate);
    }
    const runs = 200;
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      detectPitch(samples, sampleRate);
    }
    stopwatch.stop();
    final averageMs = stopwatch.elapsedMicroseconds / runs / 1000;
    // ignore: avoid_print
    print('YIN: ${averageMs.toStringAsFixed(2)} ms por janela');
    expect(averageMs, lessThan(20));
  });

  test('classifyPitch identifica a corda mais próxima e o desvio em cents', () {
    final slightlySharp = 110.0 * pow(2, 10 / 1200);
    final reading = classifyPitch(slightlySharp, guitarStrings);

    expect(reading, isNotNull);
    expect(reading!.nearestString.name, 'A2');
    expect(reading.cents, closeTo(10, 0.5));
  });
}
