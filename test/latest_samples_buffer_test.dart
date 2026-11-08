import 'package:chordai/services/latest_samples_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatestSamplesBuffer', () {
    test('snapshot é null até encher a capacidade', () {
      final buffer = LatestSamplesBuffer(10);
      expect(buffer.snapshot(), isNull);
      buffer.addSamples(List<double>.generate(9, (i) => i.toDouble()));
      expect(buffer.snapshot(), isNull);
    });

    test('snapshot traz as últimas N amostras, na ordem', () {
      final buffer = LatestSamplesBuffer(10);
      buffer.addSamples(List<double>.generate(15, (i) => i.toDouble()));
      // As 10 mais recentes de 0..14 são 5..14.
      expect(buffer.snapshot(), List<double>.generate(10, (i) => 5.0 + i));
    });

    test('continua correto entre várias chamadas de addSamples', () {
      final buffer = LatestSamplesBuffer(6);
      buffer.addSamples([1, 2, 3]);
      buffer.addSamples([4, 5]);
      expect(buffer.snapshot(), isNull); // só 5 de 6
      buffer.addSamples([6, 7]);
      // últimas 6 de [1,2,3,4,5,6,7] são [2,3,4,5,6,7]
      expect(buffer.snapshot(), [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
    });

    test('reset esquece as amostras antigas', () {
      final buffer = LatestSamplesBuffer(4);
      buffer.addSamples([1, 2, 3, 4]);
      expect(buffer.isFull, isTrue);
      buffer.reset();
      expect(buffer.isFull, isFalse);
      expect(buffer.snapshot(), isNull);
    });
  });
}
