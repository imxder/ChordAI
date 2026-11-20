import 'dart:io';
import 'dart:math';

import 'package:chordai/services/pitch_detector.dart';
import 'package:chordai/services/pitch_smoother.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wav_fixture.dart';

const _fixturesDir = 'test/fixtures/strings';
const _windowSize = 4096;
const _hopSize = 1024;
const _minHitRate = 0.9;

double _noteFrequency(String name) {
  final match = RegExp(r'^([A-G])(#?)(-?\d)$').firstMatch(name);
  if (match == null) throw FormatException('nome de nota inválido: $name');
  const semitones = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final midi =
      (int.parse(match[3]!) + 1) * 12 +
      semitones[match[1]]! +
      (match[2]!.isEmpty ? 0 : 1);
  return 440.0 * pow(2, (midi - 69) / 12);
}

double _rms(List<double> window) {
  var sum = 0.0;
  for (final s in window) {
    sum += s * s;
  }
  return sqrt(sum / window.length);
}

void main() {
  final dir = Directory(_fixturesDir);
  final files = dir.existsSync()
      ? (dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.wav'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  if (files.isEmpty) {
    test(
      'gravações reais de cordas',
      () {},
      skip: 'nenhum .wav em $_fixturesDir',
    );
    return;
  }

  for (final file in files) {
    final note = file.uri.pathSegments.last.replaceAll(
      RegExp(r'\.wav$', caseSensitive: false),
      '',
    );
    test('gravação $note', () {
      final expected = _noteFrequency(note);
      final wav = readWav(file);

      // Saída bruta do detector (janelas de 4096 amostras, sem sobreposição):
      // só reportada, não é mais a exigência do teste (ver saída suavizada).
      var voiced = 0;
      var hits = 0;
      final misses = <String>[];
      for (
        var start = 0;
        start + _windowSize <= wav.samples.length;
        start += _windowSize
      ) {
        final window = wav.samples.sublist(start, start + _windowSize);
        if (_rms(window) < silenceRmsThreshold) continue;
        voiced++;
        final detected = detectPitch(window, wav.sampleRate);
        final cents = detected == null
            ? null
            : 1200 * log(detected / expected) / ln2;
        if (cents != null && cents.abs() <= 50) {
          hits++;
        } else {
          misses.add(detected?.toStringAsFixed(1) ?? 'null');
        }
      }
      expect(voiced, greaterThan(0), reason: '$note: nenhuma janela com som');
      // ignore: avoid_print
      print(
        '$note (bruto): $hits de $voiced janelas certas; erradas: ${misses.join(', ')}',
      );

      // Saída suavizada (o que de fato aparece na tela): janela deslizante
      // com salto de 1024 amostras, igual ao TunerService, passando pelo
      // PitchSmoother. O relógio sintético avança no ritmo do áudio, não do
      // relógio real, pra reproduzir o timeout de silêncio sem precisar
      // esperar de verdade.
      var smoothedAt = DateTime(2000);
      final hopDuration = Duration(
        microseconds: (_hopSize * 1000000 / wav.sampleRate).round(),
      );
      final smoother = PitchSmoother(clock: () => smoothedAt);
      var smoothedVoiced = 0;
      var smoothedHits = 0;
      final smoothedMisses = <String>[];
      for (
        var start = 0;
        start + _windowSize <= wav.samples.length;
        start += _hopSize
      ) {
        final window = wav.samples.sublist(start, start + _windowSize);
        final estimate = detectPitchWithConfidence(window, wav.sampleRate);
        final smoothedFrequency = smoother.update(estimate);
        smoothedAt = smoothedAt.add(hopDuration);
        if (smoothedFrequency == null) continue;
        smoothedVoiced++;
        final cents = 1200 * log(smoothedFrequency / expected) / ln2;
        if (cents.abs() <= 50) {
          smoothedHits++;
        } else {
          smoothedMisses.add(smoothedFrequency.toStringAsFixed(1));
        }
      }
      expect(
        smoothedVoiced,
        greaterThan(0),
        reason: '$note: PitchSmoother nunca deu leitura',
      );
      expect(
        smoothedHits / smoothedVoiced,
        greaterThanOrEqualTo(_minHitRate),
        reason:
            '$note (suavizado): $smoothedHits de $smoothedVoiced leituras certas; erradas: ${smoothedMisses.join(', ')}',
      );
    });
  }
}
