// Roda no aparelho/simulador (flutter test integration_test/chord_model_equivalence_test.dart),
// não no `flutter test` normal: o tflite_flutter precisa da biblioteca
// nativa do TFLite do sistema de destino, que o `flutter test` (no
// computador) não tem configurada — ver test/latest_samples_buffer_test.dart
// e test/chord_stabilizer_test.dart pra a lógica pura, testada normalmente.
import 'dart:convert';
import 'dart:typed_data';

import 'package:chordai/models/chord_model_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Lê um WAV PCM16 mono a partir dos bytes (sem acesso a arquivo — os
/// bytes vêm de um asset, que funciona igual num app de verdade rodando no
/// aparelho).
List<double> _parseWavPcm16(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  String tag(int offset) => String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw const FormatException('não é um WAV');
  }

  int? channels;
  int? bitsPerSample;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = tag(offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      channels = data.getUint16(body + 2, Endian.little);
      bitsPerSample = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (bitsPerSample != 16) {
        throw const FormatException('só PCM de 16 bits');
      }
      final frameBytes = 2 * (channels ?? 1);
      final end = (body + size).clamp(0, bytes.length);
      final samples = <double>[];
      for (var i = body; i + frameBytes <= end; i += frameBytes) {
        samples.add(data.getInt16(i, Endian.little) / 32768.0);
      }
      return samples;
    }
    // Chunks de tamanho ímpar têm um byte de preenchimento.
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('sem chunk data');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saída do modelo bate com example_expected.json', (tester) async {
    final modelInfo = await ChordModelInfo.load();

    final wavBytes =
        (await rootBundle.load('assets/models/example.wav')).buffer.asUint8List();
    final samples = _parseWavPcm16(wavBytes);
    expect(samples.length, modelInfo.inputSamples);

    final expectedJson = jsonDecode(
      await rootBundle.loadString('assets/models/example_expected.json'),
    ) as Map<String, dynamic>;
    final expectedFloat32 = expectedJson['float32'] as Map<String, dynamic>;
    final expectedProbabilities =
        (expectedFloat32['probabilities'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as num).toDouble()));

    final interpreter =
        await Interpreter.fromAsset('assets/models/chord_model.tflite');
    final input = [Float32List.fromList(samples)];
    final output = [List<double>.filled(modelInfo.labels.length, 0.0)];
    interpreter.run(input, output);
    interpreter.close();

    for (var i = 0; i < modelInfo.labels.length; i++) {
      final label = modelInfo.labels[i];
      expect(
        output[0][i],
        closeTo(expectedProbabilities[label]!, 1e-3),
        reason: 'probabilidade de $label',
      );
    }

    var bestIndex = 0;
    for (var i = 1; i < output[0].length; i++) {
      if (output[0][i] > output[0][bestIndex]) bestIndex = i;
    }
    expect(modelInfo.labels[bestIndex], expectedFloat32['top_class']);
    expect(
      output[0][bestIndex],
      closeTo((expectedFloat32['top_confidence'] as num).toDouble(), 1e-3),
    );
  });
}
