import 'dart:math';

import 'package:chordai/models/tuner_note.dart';
import 'package:chordai/services/pitch_detector.dart';
import 'package:flutter_test/flutter_test.dart';

List<double> _sineWave(double frequency, double sampleRate, int numSamples) {
  return List.generate(
    numSamples,
    (i) => sin(2 * pi * frequency * i / sampleRate),
  );
}

void main() {
  const sampleRate = 22050.0;

  test('detecta corretamente a frequência de cada corda do violão', () {
    for (final string in guitarStrings) {
      final samples = _sineWave(string.frequency, sampleRate, 4096);
      final detected = detectPitch(samples, sampleRate);

      expect(detected, isNotNull, reason: 'não detectou pitch pra ${string.name}');
      final errorHz = (detected! - string.frequency).abs();
      expect(
        errorHz,
        lessThan(string.frequency * 0.01),
        reason: '${string.name}: esperado ~${string.frequency}Hz, detectou ${detected}Hz',
      );
    }
  });

  test('retorna null pra silêncio', () {
    final silence = List.filled(4096, 0.0);
    expect(detectPitch(silence, sampleRate), isNull);
  });

  test('classifyPitch identifica a corda mais próxima e o desvio em cents', () {
    final slightlySharp = 110.0 * pow(2, 10 / 1200);
    final reading = classifyPitch(slightlySharp);

    expect(reading, isNotNull);
    expect(reading!.nearestString.name, 'A2');
    expect(reading.cents, closeTo(10, 0.5));
  });
}
