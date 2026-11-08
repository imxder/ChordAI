import 'package:chordai/services/pcm16_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _syntheticBytes(int length) =>
    List<int>.generate(length, (i) => (i * 37 + 5) % 256);

void main() {
  group('Pcm16Decoder', () {
    test('chunks de tamanho ímpar dão as mesmas amostras que o buffer inteiro', () {
      // Tamanho total ímpar de propósito: sobra sempre um byte pendente, em
      // ambos os caminhos, no finalzinho.
      final allBytes = _syntheticBytes(4096 * 2 + 37);
      final whole = Pcm16Decoder().decode(allBytes);

      final chunked = Pcm16Decoder();
      final samples = <double>[];
      const chunkSizes = [1, 3, 4097];
      var offset = 0;
      var sizeIndex = 0;
      while (offset < allBytes.length) {
        final size = chunkSizes[sizeIndex % chunkSizes.length];
        sizeIndex++;
        final end = (offset + size).clamp(0, allBytes.length);
        samples.addAll(chunked.decode(allBytes.sublist(offset, end)));
        offset = end;
      }

      expect(samples, whole);
    });

    test('byte isolado só vira amostra quando o próximo chunk completa o par', () {
      final decoder = Pcm16Decoder();
      expect(decoder.decode([0x34]), isEmpty);

      final samples = decoder.decode([0x12]);
      expect(samples, hasLength(1));
      var value = 0x34 | (0x12 << 8);
      if (value >= 0x8000) value -= 0x10000;
      expect(samples.first, closeTo(value / 32768.0, 1e-9));
    });

    test('reset descarta o byte pendente', () {
      final decoder = Pcm16Decoder();
      decoder.decode([0x01]);
      decoder.reset();
      expect(decoder.decode([0x02, 0x03]), hasLength(1));
    });
  });
}
