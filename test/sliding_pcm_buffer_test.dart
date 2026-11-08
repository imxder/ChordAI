import 'package:chordai/services/sliding_pcm_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlidingPcmBuffer', () {
    test('janelas ficam corretas e em ordem com chunks irregulares', () {
      const windowSize = 16;
      const hopSize = 4;
      final buffer = SlidingPcmBuffer(windowSize: windowSize, hopSize: hopSize);

      // Sequência conhecida (0, 1, 2, ...) pra conseguir checar cada janela
      // contra o pedaço esperado dela, amostra por amostra.
      const total = 200;
      final all = List<double>.generate(total, (i) => i.toDouble());

      // Tamanhos de chunk irregulares de propósito: menores, maiores e
      // alguns bem maiores que o próprio hop ou a janela.
      const chunkSizes = [1, 3, 7, 16, 2, 40, 5, 9, 1, 1, 50, 30, 11];
      final emitted = <List<double>>[];
      var offset = 0;
      for (final size in chunkSizes) {
        final end = (offset + size).clamp(0, total);
        if (offset >= end) break;
        final chunk = all.sublist(offset, end);
        offset = end;
        for (final window in buffer.addSamples(chunk)) {
          emitted.add(window);
        }
      }

      expect(emitted, isNotEmpty);

      // A n-ésima janela emitida deve ser exatamente all[n*hop .. n*hop+window).
      for (var n = 0; n < emitted.length; n++) {
        final expectedStart = n * hopSize;
        final expected = all.sublist(expectedStart, expectedStart + windowSize);
        expect(
          emitted[n],
          expected,
          reason: 'janela $n deveria ser $expected, veio ${emitted[n]}',
        );
      }

      // Confirma que coube pelo menos todas as janelas possíveis até onde o
      // buffer leu (nenhuma janela "perdida" por chunk pequeno demais).
      final expectedCount = (offset - windowSize) ~/ hopSize + 1;
      expect(emitted.length, expectedCount);
    });

    test('um chunk só maior que várias janelas emite todas elas em ordem', () {
      const windowSize = 8;
      const hopSize = 2;
      final buffer = SlidingPcmBuffer(windowSize: windowSize, hopSize: hopSize);

      final chunk = List<double>.generate(30, (i) => i.toDouble());
      final emitted = buffer.addSamples(chunk);

      expect(emitted.length, (30 - windowSize) ~/ hopSize + 1);
      for (var n = 0; n < emitted.length; n++) {
        final expectedStart = n * hopSize;
        expect(emitted[n], chunk.sublist(expectedStart, expectedStart + windowSize));
      }
    });

    test('nenhuma janela antes de acumular o tamanho mínimo', () {
      const windowSize = 10;
      const hopSize = 3;
      final buffer = SlidingPcmBuffer(windowSize: windowSize, hopSize: hopSize);

      final emitted = buffer.addSamples(List<double>.generate(9, (i) => i.toDouble()));
      expect(emitted, isEmpty);
    });
  });
}
