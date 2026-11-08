import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:chordai/services/pitch_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixturesDir = 'test/fixtures/strings';
const _windowSize = 4096;
const _minHitRate = 0.9;

class _Wav {
  final double sampleRate;
  final List<double> samples;

  const _Wav(this.sampleRate, this.samples);
}

_Wav _readWav(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  String tag(int offset) => String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw FormatException('${file.path} não é WAV');
  }

  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = tag(offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
      bitsPerSample = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (channels == null || sampleRate == null) break;
      if (bitsPerSample != 16) {
        throw FormatException('${file.path}: só PCM de 16 bits');
      }
      final frameBytes = 2 * channels;
      final end = min(body + size, bytes.length);
      final samples = <double>[];
      for (var i = body; i + frameBytes <= end; i += frameBytes) {
        samples.add(data.getInt16(i, Endian.little) / 32768.0);
      }
      return _Wav(sampleRate.toDouble(), samples);
    }
    // Chunks de tamanho ímpar têm um byte de preenchimento.
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw FormatException('${file.path}: sem chunk fmt/data');
}

double _noteFrequency(String name) {
  final match = RegExp(r'^([A-G])(#?)(-?\d)$').firstMatch(name);
  if (match == null) throw FormatException('nome de nota inválido: $name');
  const semitones = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final midi = (int.parse(match[3]!) + 1) * 12 +
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
    test('gravações reais de cordas', () {}, skip: 'nenhum .wav em $_fixturesDir');
    return;
  }

  for (final file in files) {
    final note = file.uri.pathSegments.last.replaceAll(RegExp(r'\.wav$', caseSensitive: false), '');
    test('gravação $note', () {
      final expected = _noteFrequency(note);
      final wav = _readWav(file);
      var voiced = 0;
      var hits = 0;
      final misses = <String>[];
      for (var start = 0; start + _windowSize <= wav.samples.length; start += _windowSize) {
        final window = wav.samples.sublist(start, start + _windowSize);
        if (_rms(window) < silenceRmsThreshold) continue;
        voiced++;
        final detected = detectPitch(window, wav.sampleRate);
        final cents = detected == null ? null : 1200 * log(detected / expected) / ln2;
        if (cents != null && cents.abs() <= 50) {
          hits++;
        } else {
          misses.add(detected?.toStringAsFixed(1) ?? 'null');
        }
      }
      expect(voiced, greaterThan(0), reason: '$note: nenhuma janela com som');
      expect(
        hits / voiced,
        greaterThanOrEqualTo(_minHitRate),
        reason: '$note: $hits de $voiced janelas certas; erradas: ${misses.join(', ')}',
      );
    });
  }
}
